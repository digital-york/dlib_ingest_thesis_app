require 'nokogiri'
require 'nokogiri-pretty'

require 'dotenv'

require 'activemessaging'
include ActiveMessaging::MessageSender

class ThesesController < ApplicationController
  before_action :set_thesis, only: [:show, :edit, :update, :destroy]

  # GET /theses
  # GET /theses.json
  def index
    #Dotenv.load
    @theses = Thesis.all
  end

  # GET /theses/1
  # GET /theses/1.json
  def show
  end

  # GET /theses/new
  def new
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

    @uploaded_file = UploadedFile.new

  end

  # GET /theses/1/edit
  def edit
  end

  # POST /theses
  # POST /theses.json
  def create
    #@uploaded_file = UploadedFile.new(uploaded_file_params)

    metadata_file_path = '/var/tmp/' + SecureRandom.uuid + '.dc'
    File.open(metadata_file_path, "w+") do |f|
      f.write(add_bioler_plate_fields(get_thesis_xml.to_xml))
    end

    wf_client_file_path = '/var/tmp/' + SecureRandom.uuid + '.wf.client'
    File.open(wf_client_file_path, "w+") do |f|
      f.write(get_workflow_client_thesis_xml(metadata_file_path).to_xml)
    end

    uf = params[:uploaded_files]
    #puts '=============@thesis uploaded files============='
    #puts uf.inspect
    #puts uf.original_filename
    #puts File.absolute_path(uf.tempfile)
    #puts uf.content_type
    #puts uf.headers
    #puts '=============end of @thesis uploaded files============='

    publish :'workflow_queue', get_workflow_client_thesis_xml(metadata_file_path).to_xml, {'suppress_content_length' => true}
    #publish :'workflow_queue', get_workflow_client_thesis_xml_single_file(metadata_file_path, File.absolute_path(uf.tempfile), "true", "ture", uf.content_type).to_xml, {'suppress_content_length' => true}


    #puts '=============@thesis_params============='
    #puts thesis_params.inspect
    #puts '=============@thesis_params============='


    @thesis = Thesis.new(thesis_params)

    if self.current_user!=nil and self.current_user.email!=nil
      ThesisMailer.submitted(self.current_user.email).deliver
    end

    respond_to do |format|
      if @thesis.save
        format.html { redirect_to @thesis, notice: 'Thesis was successfully created.' }
        format.json { render :show, status: :created, location: @thesis }
      else
        format.html { render :new }
        format.json { render json: @thesis.errors, status: :unprocessable_entity }
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
      creator     = thesis_params[:creator]
      title       = thesis_params[:title]
      date        = thesis_params[:date]
      desc        = thesis_params[:description]
      degreetype  = thesis_params[:degree_type]
      contributor = thesis_params[:contributor]
      publisher   = thesis_params[:publisher]
      subject     = thesis_params[:subject]
      rights      = thesis_params[:rights]
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

    def add_bioler_plate_fields(xml_string)
      doc = Nokogiri::XML(xml_string)
      root = doc.root
      root.add_namespace 'oai_dc', 'http://www.openarchives.org/OAI/2.0/oai_dc/'
      root.add_namespace 'dc',      'http://purl.org/dc/elements/1.1/'
      # publisher = ''
      # root.xpath('dc:publisher').each do |pub|
      #   publisher = pub.content
      # end
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
        key_str.sub! '_', ':'
        if key_str!='dc:rights'
          Settings.thesis.boiler_plate[key].to_hash.values.each do |value|
            root.add_child('<'+key_str+'>'+value.to_s+'</'+key_str+'>')
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




  private
    # Use callbacks to share common setup or constraints between actions.
    def set_thesis
      @thesis = Thesis.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def thesis_params
      params.require(:thesis).permit(:name, :title, :date, :abstract, :degreetype, :supervisor, :department, :subjectkeyword, :rightsholder, :licence, :uploaded_files)
      #params.require(:thesis).permit!
    end

    # def uploaded_file_params
    #   params.require(:uploaded_file).permit(:file_uid, :title)
    # end
end
