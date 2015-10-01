require 'nokogiri'
require 'nokogiri-pretty'

require 'dotenv'
require 'fileutils'

require 'activemessaging'
include ActiveMessaging::MessageSender

class ThesesController < ApplicationController
  #before_action :set_thesis, only: [:show, :edit, :update, :destroy]
  before_action :set_thesis, only: [:show]
  before_action :authenticate_user!

  # GET /theses
  # GET /theses.json
  def index
    #Dotenv.load
    @theses = Thesis.all

    @uploaded_files = UploadedFile.all
  end

  # GET /theses/1
  # GET /theses/1.json
  def show

  end

  # GET /theses/new
  def new
    owner = 'public'
    #@uploaded_file = UploadedFile.new

    @thesis = Thesis.new
    if self.current_user!=nil and self.current_user.surname!=nil and self.current_user.givenname!=nil
        @thesis.name = self.current_user.surname + ', ' + self.current_user.givenname
        @thesis.rightsholder = @thesis.name
    end

    @years        = Time.now.year.step(1960, -1)
    @thesis.date  = Time.now.year

    @degree_types = Settings.thesis.degreetype.to_hash.values
    @departments  = Settings.thesis.ldap.department.to_hash.values
    #@licences     = Settings.thesis.licencetype.to_hash.invert
    @licences     = Settings.thesis.licencetype.to_hash

    if self.current_user!=nil and self.current_user.department!=nil
      @thesis.department = self.current_user.department
    end

    if self.current_user!=nil #and self.current_user.department!=nil
      owner = current_user.login
    end

    # @uploaded_files = UploadedFile.new
    @uploaded_files = UploadedFile.where("owner='"+owner+"'")
    #if !@uploaded_files.nil?
    #  @uploaded_file = @uploaded_files.first
    #end
    #puts "@uploaded_files"

    # puts "----------@uploaded_files------------"
    # puts @uploaded_files.inspect
    # @uploaded_files.each do |file|
    #   puts "owner: "
    #   puts file.owner
    #   puts "original name: "
    #   puts file.original_name
    # end
    # puts "----------------------"
    # puts "END of @uploaded_files"

  end

  # GET /theses/1/edit
  def edit
  end

  # POST /theses
  # POST /theses.json
  def create
    submission_type    = params[:submission_type]
    default_thumbnails = Settings.thesis.thumbnails.default_icons.to_hash

    if 'upload' == submission_type
      uf = params[:uploaded_files]
      s = uf.inspect
      start_index = s.index('UploadedFile:')+'UploadedFile:'.length
      end_index   = start_index + 16

      uf_uid = s[start_index..end_index].strip
      #logger.debug "uf_uid: "
      #logger.debug uf_uid

      respond_to do |format|
        owner = 'public'
        if self.current_user!=nil
          owner = current_user.login
        end

        filepath   = Rails.root.to_s + Settings.thesis.tmpfilepath
        tmpfileurl = Settings.thesis.tmpfileurl
        if !dir_exist?(filepath)
          Dir.mkdir filepath
        end
        fulltmpfilename = File.absolute_path(uf.tempfile).to_s
        tmpfilename     = fulltmpfilename[(fulltmpfilename.rindex('/')+1)..-1].downcase
        #puts "Moving file: "
        #puts fulltmpfilename
        #puts filepath + tmpfilename
        FileUtils.copy(fulltmpfilename, filepath + tmpfilename)

        thumbnail = 'nothumbnail.png'

        if tmpfilename.end_with? 'pdf'
          thumbnail = default_thumbnails['pdf'.to_sym]
        elsif tmpfilename.end_with? 'doc'
          thumbnail = default_thumbnails['doc'.to_sym]
        elsif tmpfilename.end_with? 'docx'
          thumbnail = default_thumbnails['docx'.to_sym]
        elsif tmpfilename.end_with? 'zip'
          thumbnail = default_thumbnails['zip'.to_sym]
        elsif (tmpfilename.end_with? 'jpg') || (tmpfilename.end_with? 'jpeg') || (tmpfilename.end_with? 'png')
          logger.debug 'Generating thumbnail'
          thumbnail = tmpfilename + Settings.thesis.thumbnails.fileextension.to_s
          cmd = 'convert -resize x100 ' + filepath + tmpfilename + ' ' + filepath + thumbnail
          thumbnail = tmpfileurl + thumbnail
          system(cmd)
        else
          thumbnail = default_thumbnails['nothum'.to_sym]
        end
        # puts 'thumbnail'
        # puts thumbnail

        t = Time.new
        @uploaded_file = UploadedFile.new(uf_uid: uf_uid,
                                   uf_name: uf.original_filename,
                                   title: uf.original_filename,
                                   original_name: uf.original_filename,
                                   #tmp_name: File.absolute_path(uf.tempfile),
                                   tmp_name: filepath + tmpfilename,
                                   content_type: uf.content_type,
                                   thumbnail: thumbnail,
                                   owner: owner,
                                   main: "false",   #By default, newly uploaded file is not the main file
                                   created_at: t,
                                   updated_at: t)
        @uploaded_file.save

        @thesis = Thesis.new
        if self.current_user!=nil and self.current_user.surname!=nil and self.current_user.givenname!=nil
          @thesis.name = self.current_user.surname + ', ' + self.current_user.givenname
        end

        @years        = Time.now.year.step(1960, -1)
        @thesis.date  = Time.now.year

        @degree_types = Settings.thesis.degreetype.to_hash.values
        @departments  = Settings.thesis.ldap.department.to_hash.values
        #@licences     = Settings.thesis.licencetype.to_hash.invert
        @licences     = Settings.thesis.licencetype.to_hash

        if self.current_user!=nil and self.current_user.department!=nil
          @thesis.department = self.current_user.department
        end

        format.html {redirect_to new_theses_path}
        format.js
      end
    elsif 'submit' == submission_type # processing metadata submission
      mainfileid = params[:mainfile]
      logger.debug "Received post request: submit"
      more_supervisors = params[:more_supervisors]
      more_departments = params[:more_departments]
      more_subject_keywords = params[:more_subject_keywords]

      metadata_file_path = '/var/tmp/' + SecureRandom.uuid + '.dc'
      File.open(metadata_file_path, "w+") do |f|
        f.write(add_bioler_plate_fields(get_thesis_xml(more_supervisors, more_departments, more_subject_keywords).to_xml))
      end

      wf_client_file_path = '/var/tmp/' + SecureRandom.uuid + '.wf.client'
      wf_client_content  = get_workflow_client_thesis_xml_multi_files_from_db(metadata_file_path, mainfileid).to_xml
      File.open(wf_client_file_path, "w+") do |f|
        f.write(wf_client_content)
      end
      publish :'workflow_queue', wf_client_content, {'suppress_content_length' => true}
      #publish :'workflow_queue', get_workflow_client_thesis_xml(metadata_file_path).to_xml, {'suppress_content_length' => true}
      #publish :'workflow_queue', get_workflow_client_thesis_xml_single_file(metadata_file_path, File.absolute_path(uf.tempfile), "true", "ture", uf.content_type).to_xml, {'suppress_content_length' => true}

      @thesis = Thesis.new(thesis_params)

      if self.current_user!=nil and self.current_user.email!=nil
        ThesisMailer.submitted(self.current_user.email, get_thesis_summary(more_supervisors, more_departments, more_subject_keywords)).deliver_now
      end
      # remove file record and thumbnail if being generated
      remove_uploaded_files_from_db()
	  
      respond_to do |format|
        if @thesis.save
          logger.debug "Thesis saved successfully, redirecting..."
          format.html {
            redirect_to @thesis, notice: 'Thesis was successfully created.'
            return
          }
          format.json {
            render :show, status: :created, location: @thesis
          }
        else
          format.html { render :new }
          format.json { render json: @thesis.errors, status: :unprocessable_entity }
          return
        end
      end
    end

  end

  # PATCH/PUT /theses/1
  # PATCH/PUT /theses/1.json
  def update
    respond_to do |format|
      if @thesis.update(thesis_params)
        format.html { redirect_to @thesis, notice: 'Thesis was successfully updated.' }
        format.json { render :show, status: :ok, location: @thesis }
      else
        format.html { render :edit }
        format.json { render json: @thesis.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /theses/1
  # DELETE /theses/1.json
  def destroy
    @thesis.destroy
    respond_to do |format|
      format.html { redirect_to theses_url, notice: 'Thesis was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def get_thesis_xml
      creator     = thesis_params[:name]
      title       = thesis_params[:title]
      date        = thesis_params[:date]
      desc        = thesis_params[:abstract]
      degreetype  = thesis_params[:degree_type]
      contributor = thesis_params[:supervisor]
      publisher   = thesis_params[:department]
      subject     = thesis_params[:subjectkeyword]
      rights      = thesis_params[:rightsholder]
      licence     = thesis_params[:licence]

      builder = Nokogiri::XML::Builder.new do |xml|
        xml['oai_dc'].dc('xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/', 'xmlns:dc' => 'http://purl.org/dc/elements/1.1/') {
          xml['dc'].creator creator
          xml['dc'].title title
          xml['dc'].date date
          xml['dc'].description desc
          xml['dc'].type degreetype
          xml['dc'].contributor contributor
          xml['dc'].publisher publisher
          xml['dc'].subject subject
          xml['dc'].rights rights
          xml['dc'].licence licence
        }
      end
    end

    def get_thesis_xml(more_supervisors, more_departments, more_subject_keywords)
      creator     = thesis_params[:name]
      title       = thesis_params[:title]
      date        = thesis_params[:date]
      desc        = thesis_params[:abstract]
      degreetype  = thesis_params[:degreetype]
      contributor = thesis_params[:supervisor]
      publisher   = thesis_params[:department]
      subject     = thesis_params[:subjectkeyword]
      rights      = thesis_params[:rightsholder]
      licence     = thesis_params[:licence]

      builder = Nokogiri::XML::Builder.new do |xml|
        xml['oai_dc'].dc('xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/', 'xmlns:dc' => 'http://purl.org/dc/elements/1.1/') {
          if !creator.nil? and creator!=''
            xml['dc'].creator creator
          end
          if !title.nil? and title!=''
            xml['dc'].title title
          end
          if !date.nil? and date!=''
            xml['dc'].date date
          end
          if !desc.nil? and desc!=''
            xml['dc'].description desc
          end
          if !degreetype.nil? and degreetype!=''
            xml['dc'].type degreetype
          end
          if !contributor.nil? and contributor!=''
            xml['dc'].contributor contributor
          end
          if !more_supervisors.nil?
            more_supervisors.each do |sup|
              if !sup.nil? and sup!=''
                xml['dc'].contributor sup
              end
            end
          end

          if !publisher.nil? and publisher!=''
            xml['dc'].publisher publisher
          end
          if !more_departments.nil?
            more_departments.each do |dep|
              if !dep.nil? and dep!=''
                xml['dc'].publisher dep
              end
            end
          end

          # Add first subject
          if !subject.nil? and subject!=''
            xml['dc'].subject subject
          end
          # Add other optional subjects
          if !more_subject_keywords.nil?
            more_subject_keywords.each do |sub|
              if !sub.nil? and sub!=''
                xml['dc'].subject sub
              end
            end
          end

          if !rights.nil? and rights!=''
            xml['dc'].rights rights
          end
          # xml['dc'].licence licence
        }
      end
    end

    def get_thesis_summary(more_supervisors, more_departments, more_subject_keywords)
	  creator     = thesis_params[:name]
      title       = thesis_params[:title]
      date        = thesis_params[:date]
      desc        = thesis_params[:abstract]
      degreetype  = thesis_params[:degreetype]
      contributor = thesis_params[:supervisor]
      publisher   = thesis_params[:department]
      subject     = thesis_params[:subjectkeyword]
      rights      = thesis_params[:rightsholder]
      licencekey  = thesis_params[:licence]
      @licences     = Settings.thesis.licencetype.to_hash	  
	  licence     = @licences[licencekey.to_sym]  
	  
	  crlf = '<br/>'
	  summarytext = "<h3>Your thesis has been submitted successfully.</h3>"
	  summarytext = summarytext + "<h4>Submission summary</h4>" 
	  summarytext = summarytext + "<b>Author</b>: "               + creator + crlf
	  summarytext = summarytext + "<b>Dissertation title</b>: "   + title  + crlf
	  summarytext = summarytext + "<b>Date</b>: "                 + date.to_s + crlf
	  summarytext = summarytext + "<b>Abstract</b>: "             + desc + crlf
	  summarytext = summarytext + "<b>Degree type</b>: "          + degreetype + crlf
	  summarytext = summarytext + "<b>Degree supervisor(s)</b>: " + contributor
	  if !more_supervisors.nil?
            more_supervisors.each do |sup|
              if !sup.nil? and sup!=''
                summarytext = summarytext + " " + sup 
              end
            end
      end
	  summarytext = summarytext + crlf
	  
	  summarytext = summarytext + "<b>Department</b>: "           + publisher 
	  if !more_departments.nil?
            more_departments.each do |dep|
              if !dep.nil? and dep!=''
                summarytext = summarytext + " " + dep
              end
            end
      end
      summarytext = summarytext + crlf
	  
	  summarytext = summarytext + "<b>Subject keywords</b>: "     + subject
          if !more_subject_keywords.nil?
            more_subject_keywords.each do |sub|
              if !sub.nil? and sub!=''
                summarytext = summarytext + " " + sub
              end
            end
      end
	  summarytext = summarytext + crlf
	  summarytext = summarytext + "<b>Rights holder</b>: "        + rights + crlf
	  summarytext = summarytext + "<b>Licence</b>: "              + licence + crlf
      
	  summarytext = summarytext + crlf
	  summarytext = summarytext + "<h4>Uploaded files</h4>" 
	  
	  owner = 'public'
      if self.current_user!=nil
        owner = current_user.login
      end
      files = UploadedFile.where("owner=?", owner)

      if !files.nil?
        files.each do |f|
		  summarytext = summarytext + f.original_name + crlf
       end
      end
	  
	  summarytext 
	  
    end	
	
    def add_bioler_plate_fields(xml_string)
      doc = Nokogiri::XML(xml_string)
      root = doc.root
      root.add_namespace 'oai_dc', 'http://www.openarchives.org/OAI/2.0/oai_dc/'
      root.add_namespace 'dc',      'http://purl.org/dc/elements/1.1/'

      publisher  = thesis_params[:publisher]
      degreetype = thesis_params[:degree_type]

      Settings.thesis.degreetype.to_hash.keys.each do |key|
        if degreetype == Settings.thesis.degreetype[key]
          dc_type_value = Settings.thesis.degreetype_to_dctype[key].to_s
          root.add_child('<dc:type>'+dc_type_value+'</dc:type>')
        end
      end
      #root.add_child('<dc:type>TEST</dc:type>')

      #process boiler plate fields
      Settings.thesis.boiler_plate.to_hash.keys.each do |key|
        key_str = key.to_s
        orig_key_str = key_str.clone
        key_str.sub! '_', ':'
        orig_key_str.sub! '_', ':'
        if key_str!='dc:rights'
          if key_str.start_with? "dc:type"
            key_str = "dc:type"
          end

          # dc_type in settings.yml is kind of reserved by Thesis
          # other content models added later, e.g. dc_type_coll, dc_type_schol, and dc_type_exam need to do
          # additional checks before adding dc types
          if orig_key_str=="dc:type"
            Settings.thesis.boiler_plate[key].to_hash.values.each do |value|
              root.add_child('<'+key_str+'>'+value.to_s+'</'+key_str+'>')
            end
          end
        else
          public_dept_list = Settings.thesis.boiler_plate.dc_rights.public_department_list.to_hash.values
          if public_dept_list.include? publisher
            Settings.thesis.boiler_plate.dc_rights.public_rights.to_hash.values.each do |value|
              root.add_child('<'+key_str+'>'+value.to_s+'</'+key_str+'>')
            end
          else
            Settings.thesis.boiler_plate.dc_rights.york_restricted.to_hash.values.each do |value|
              root.add_child('<'+key_str+'>'+value.to_s+'</'+key_str+'>')
            end
          end
        end
      end
      #t = doc.to_xml(:indent => 2)
      t = doc.human
    end
    def get_workflow_client_thesis_xml(metadata_file)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml['wf'].workflow('xmlns:wf' => 'http://dlib.york.ac.uk/workflow') {
          xml['wf'].client(:scenarioid => Settings.thesis.scenarioid, :parent =>Settings.thesis.parentcollection, :submittedBy => Settings.thesis.submittedBy, :client => Settings.thesis.client, :stopOnError => Settings.thesis.stopOnError, :accesskey => Settings.thesis.accesskey) {
            xml['wf'].file(:mime => 'text/xml', :id => 'DC', :file => metadata_file)
          }
        }
      end
    end
    def get_workflow_client_thesis_xml_single_file(metadata_file, uploaded_file_name, uploaded_file_main, uploaded_file_storelocally, uploaded_file_mime)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml['wf'].workflow('xmlns:wf' => 'http://dlib.york.ac.uk/workflow') {
          xml['wf'].client(:scenarioid => Settings.thesis.scenarioid, :parent =>Settings.thesis.parentcollection, :submittedBy => Settings.thesis.submittedBy, :client => Settings.thesis.client, :stopOnError => Settings.thesis.stopOnError, :accesskey => Settings.thesis.accesskey) {
            xml['wf'].file(:mime => 'text/xml', :id => 'DC', :file => metadata_file)

            xml['wf'].file(:mime => uploaded_file_mime, :main => uploaded_file_main, :storelocally => uploaded_file_storelocally, :file => uploaded_file_name)
          }
        }
      end
    end
    def get_workflow_client_thesis_xml_multi_files_from_db(metadata_file, mainfileid)
      owner = 'public'
      if self.current_user!=nil
        owner = current_user.login
      end

      builder = Nokogiri::XML::Builder.new do |xml|
        xml['wf'].workflow('xmlns:wf' => 'http://dlib.york.ac.uk/workflow') {
          xml['wf'].client(:scenarioid => Settings.thesis.scenarioid, :parent =>Settings.thesis.parentcollection, :submittedBy => Settings.thesis.submittedBy, :client => Settings.thesis.client, :stopOnError => Settings.thesis.stopOnError, :accesskey => Settings.thesis.accesskey) {
            xml['wf'].file(:mime => 'text/xml', :id => 'DC', :file => metadata_file)

            files = UploadedFile.where("owner=?", owner)

            if !files.nil?
              files.each do |f|
                if f.id.to_s == mainfileid
                  xml['wf'].file(:mime => f.content_type, :main => "true", :storelocally => "true", :file => f.tmp_name)
                else
                  xml['wf'].file(:mime => f.content_type, :main => "false", :storelocally => "true", :file => f.tmp_name)
                end
              end
            end
          }
        }
      end
    end

    def remove_uploaded_files_from_db()
      owner = 'public'
      if self.current_user!=nil
        owner = current_user.login
      end

      files = UploadedFile.where("owner=?", owner)

      if !files.nil?
         files.each do |f|
            tmp_file_name = f.tmp_name
            thumbnail     = f.thumbnail

            logger.debug "Leave " + tmp_file_name + " for workflow."

            if(thumbnail.start_with?('/uploadedfiles/'))
              fullpath = Rails.root.join('public', thumbnail).to_s
              logger.debug "Deleting " + fullpath
              File.delete(fullpath) if File.exist?(fullpath)
              logger.debug "Done."
            end

            f.destroy
         end
      end

    end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_thesis
      @thesis = Thesis.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def thesis_params
      params.require(:thesis).permit(:name, :title, :date, :abstract, :degreetype, :supervisor, :department, :subjectkeyword, :rightsholder, :licence)
      #params.require(:thesis).permit!
    end

    def uploaded_file_params
      params.permit(:file_uid, :title, :original_name, :tmp_name, :content_type, :owner, :main)
    end

    def dir_exist?(directory)
      File.directory?(directory)
    end

    def remove_uploaded_files_after_submission()
      owner = ''
      if self.current_user!=nil and self.current_user.department!=nil
        owner = current_user.login
      end

      if owner != ''
        files = UploadedFile.where("owner=?", owner)

        if !files.nil?
          files.each do |f|
            thumbnail = f.thumbnail

            if(thumbnail.start_with?('/uploadedfiles/'))
              fullpath = Rails.root.join('public', thumbnail).to_s
              logger.debug "Deleting " + fullpath
              File.delete(fullpath) if File.exist?(fullpath)
              logger.debug "Done."
            end

            f.destroy
          end
        end
      end

    end
end
