require 'csv'
require 'nokogiri'
require 'nokogiri-pretty'
require 'dotenv'
include ActionView::Helpers::TagHelper
include ActionView::Context
require 'activemessaging'
include ActiveMessaging::MessageSender

class IngestImages

  #TODO set scenario for JPEG2s

  def do_ingest(filepath, folder, content, rights, parent, worktype, photographer, repository, email)
    @scenario = Settings.image.scenarioid
    @report = ''
    @file_path = filepath
    @folder = folder
    @content = content
    @rights = rights
    @parent = parent
    @repository = repository
    @photographer = photographer
    @worktype = worktype
    @wf = nil
    # open the stored file
    begin
      @file = File.open(Settings.tmppath + email + '.csv')
      #delete this file; we've read the contents now
      #error here, investigate?
      #FileUtils.rm(Settings.tmppath + email + '.csv')
    rescue
      @report << paragraph("ERROR:#{$!}")
    end
    open_file
    process_file
    return @report, @wf
  end

  def open_file
    begin
      f = open(@file)
      @csv = CSV.read(f, :headers => true)
      f.close

    rescue
      @report << paragraph("ERROR:#{$!}")
    end
  end

  def process_file
    count = 0
    @main_file = ''
    @csv.group_by { |row| row[''] }.values.each do |group|
      group.each_with_index do |i, index|
        begin
          build_metadata(i)
          build_rights
          write_metadata_file
          write_data_files
          write_workflow_files
          @report << paragraph("Adding #{@title} to collection #{@parent}")
          # publish to the workflow queue
          publish :'workflow_queue', @wf, {'suppress_content_length' => true}
          count += 1
          #cleanup
        rescue
          @report << paragraph("ERROR line #{index + 1}:#{$!}")
        end
      end
      @report << paragraph("Processed #{count} line(s)")
    end
    return @report, get_workflow_client_thesis_xml.to_xml
  end

  def build_metadata(row)
    @title = ''
    @file_output = VraDatastream.new
    if @worktype.nil? or @worktype == ''
      @worktype = 'unknown'
    else
      @file_output.work.worktypeset.worktype = @worktype
    end
    @no_folio = false
    @title_hash = Hash.new
    row.each do |pair|
      build_metadata_from_pair(pair)
    end
    if @title_hash['rv'].nil?
      unless @title_hash['folio'].nil?
        @title_hash['folio'].gsub! ' f.',' p.'
      end
    end
    @title = "#{@title_hash['image']}#{@title_hash['part']}#{@title_hash['folio']}#{@title_hash['rv']}#{@title_hash['notes']}#{@title_hash['uv']}"
    @title.gsub '  ', ' '
    @file_output.image.titleset.title = @title
    @file_output.work.titleset.title = @title
    @file_output.work.titleset.title.lang = 'en'
    @file_output.work.locationset.location.refid = @title
    if @repository == 'borthwick' #skip the none
      @file_output.work.locationset.location.name = [Settings.repository.borthwick.name]
      @file_output.work.locationset.location.gname = [Settings.repository.borthwick.place]
    end
    @file_output.image.agentset.agent.name = @photographer
    @file_output.image.agentset.agent.role = 'photographer'
    @file_output.image.worktypeset.worktype = 'digital photograph or image'
  end

  def build_metadata_from_pair(pair)
    begin
      case pair[0].downcase
        when 'image'
          unless pair[1].nil?
            @image = pair[1]
            @title_hash['image'] = pair[1][0..-6].gsub!('_', ' ').gsub(' 000',' ').gsub(' 00',' ').gsub(' 0',' ') #this makes an assumption about the max number
            @title += ' '
          end
        when 'part'
          unless pair[1].nil?
            @title_hash['part'] = ' ' + pair[1].to_s
          end
        when 'folio'
          unless pair[1].nil?
            @title_hash['folio'] = ' f.' + pair[1].to_s
          end
        when 'recto/verso'
          unless pair[1].nil?
            if pair[1] == 'r'
              @title_hash['rv'] =  ' (recto)'
            elsif pair[1] == 'v'
              @title_hash['rv'] = ' (verso)'
            end
          end
        when 'notes'
          unless pair[1].nil?
            # use as title if there is no folio number
            @title_hash['notes'] =  ' ' + pair[1].to_s
          end
        when 'uv'
          unless pair[1].nil?
            @title_hash['uv'] = ' (UV)'
          end
        when 'parent'
          # prefer file to selection
          unless pair[1].nil?
            if pair[1].to_s.start_with?('york:')
              @parent = pair[1].to_s
            else
              @parent = 'york:' + pair[1].to_s
            end
          end
        when 'worktype'
          unless pair[1].nil?
            @file_output.work.worktypeset.worktype = pair[1].to_s
          end
      end
    rescue
      @report << paragraph("ERROR in build_metadata_from_pair #{pair[0]}:#{pair[1]}, #{$!}")
    end
  end

  def build_rights
    # inject rights
    case @rights
      when 'york_restricted'
        @file_output.image.rightsset.rights.text = Settings.rights.york_restricted.text
        @file_output.image.rightsset.rights.rightshref = Settings.rights.york_restricted.license
      when 'undetermined'
        @file_output.image.rightsset.rights.text = Settings.rights.undetermined.text
        @file_output.image.rightsset.rights.rightshref = Settings.rights.undetermined.license
      when 'uk_copyright_permitted_acts'
        @file_output.image.rightsset.rights.text = Settings.rights.uk_copyright_permitted_acts.text
        @file_output.image.rightsset.rights.rightshref = Settings.rights.uk_copyright_permitted_acts.license
      when 'creative_commons_by_nc_sa'
        @file_output.image.rightsset.rights.text = Settings.rights.creative_commons_by_nc_sa.text
        @file_output.image.rightsset.rights.rightshref = Settings.rights.creative_commons_by_nc_sa.license
      when 'creative_commons_by_nc_sa_preview'
        @file_output.image.rightsset.rights.text = Settings.rights.creative_commons_by_nc_sa_preview.text
        @file_output.image.rightsset.rights.rightshref = Settings.rights.creative_commons_by_nc_sa_preview.license
      when 'creative_commons_by_nc_nd'
        @file_output.image.rightsset.rights.text = Settings.rights.creative_commons_by_nc_nd.text
        @file_output.image.rightsset.rights.rightshref = Settings.rights.creative_commons_by_nc_nd.license
      when 'creative_commons_by_nc_nd_preview'
        @file_output.image.rightsset.rights.text = Settings.rights.creative_commons_by_nc_nd_preview.text
        @file_output.image.rightsset.rights.rightshref = Settings.rights.creative_commons_by_nc_nd_preview.license
      when 'admin_only'
        @file_output.image.rightsset.rights.text = Settings.rights.admin_only.text
        @file_output.image.rightsset.rights.rightshref = Settings.rights.admin_only.license
      when 'online_only'
        @file_output.image.rightsset.rights.text = Settings.rights.online_only.text
        @file_output.image.rightsset.rights.rightshref = Settings.rights.online_only.license
      when 'public_domain'
        @file_output.image.rightsset.rights.text = Settings.rights.public_domain.text
        @file_output.image.rightsset.rights.rightshref = Settings.rights.public_domain.license
    end
  end

  def write_metadata_file
    @metadata_file_path = Settings.tmppath + SecureRandom.uuid + '.vra'
    File.open(@metadata_file_path, "w+") do |f|
      f.write(@file_output.to_xml)
    end
  end

  def write_data_files
    begin
      if Dir.exist? @file_path+ @folder.gsub('/','') + '_JPEG2000s'
        @display_file_path = @file_path + @folder.gsub('/','') + '_JPEG2000s/' + @image + '.jp2'
        @scenario = Settings.image.scenarioid_jp2
      end
      @archival_master_file_path = @file_path + @folder.gsub('/','') + '_TIFFs/' + @image + '.tif'
      # replace spaces in files
      if @archival_master_file_path.include? ' '
        main = @archival_master_file_path.clone
        FileUtils.mv @archival_master_file_path, main.gsub!(' ','_')
        @archival_master_file_path = main
      end
      if @display_file_path.include? ' '
        main = @display_file_path.clone
        FileUtils.mv @display_file_path, main.gsub!(' ','_')
        @display_file_path = main
      end
    rescue
      @report << paragraph("ERROR in write_data_files #{$!}")
    end
  end

  def write_workflow_files
    wf_client_file_path = Settings.tmppath + SecureRandom.uuid + '.wf.client'
    @wf = get_workflow_client_thesis_xml.to_xml
    File.open(wf_client_file_path, "w+") do |f|
      f.write(@wf)
    end
  end

  # Use default collection specified in settings unless otherwise specified
  def get_workflow_client_thesis_xml
    if @parent.nil? || @parent == ''
      @parent = Settings.thesis.parentcollection
    end
    builder = Nokogiri::XML::Builder.new do |xml|
      xml['wf'].workflow('xmlns:wf' => 'http://dlib.york.ac.uk/workflow') {
        xml['wf'].client(:scenarioid => @scenario, :parent => @parent, :submittedBy => Settings.thesis.submittedBy, :client => Settings.thesis.client, :stopOnError => Settings.thesis.stopOnError, :accesskey => Settings.thesis.accesskey) {
          xml['wf'].file(:mime => 'text/xml', :id => 'VRA', :file => @metadata_file_path)

          unless @archival_master_file_path.nil?
            xml['wf'].file(:mime => 'image/tiff', :storelocally => 'true', :file => @archival_master_file_path)
          end
          unless @display_file_path.nil?
            xml['wf'].file(:mime => 'image/jp2', :storelocally => 'true', :file => @display_file_path)
          end
        }
      }
    end
  end

  def paragraph(value)
    content_tag(:p, value).html_safe
  end
end