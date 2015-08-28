require 'csv'
require 'nokogiri'
require 'nokogiri-pretty'
require 'dotenv'
include ActionView::Helpers::TagHelper
include ActionView::Context

class IngestImages

  def do_ingest(filepath, content, rights, parent, worktype, photographer, repository, email)
    @report = ''
    @file_path = filepath
    @content = content
    @rights = rights
    @parent = parent
    @repository = repository
    @photographer = photographer
    @worktype = worktype
    # open the stored file
    begin
      @file = File.open(Settings.tmppath + email + '.csv')
    rescue
      @report << paragraph("ERROR:#{$!}")
    end
    open_file
    process_file
    @report
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
    @file_output.work.worktypeset.worktype = @worktype
    row.each do |pair|
      build_metadata_from_pair(pair)
    end
    @title.gsub! '  ', ' '
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
            @title += pair[1][0..-6].gsub! '_', ' '
            @title += ' '
          end
        when 'folio'
          unless pair[1].nil?
            @title += pair[1].to_s
          end
        when 'recto/verso'
          unless pair[1].nil?
            @title += pair[1].to_s
          end
        when 'description'
          unless pair[1].nil?
            @title += pair[1].to_s
          end
        when 'notes'
          unless pair[1].nil?
            @file_output.work.descriptionset.description = pair[1].to_s
          end
        when 'parent'
          # prefer file to selection
          unless pair[1].nil?
            @parent = pair[1].to_s
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
      if @content == 'Images (TIFFs only)'
        #archival_master_file_path = Settings.tmppath + SecureRandom.uuid + '.tif'
        #FileUtils.copy @file_path + image + '.tif', archival_master_file_path
        @archival_master_file_path = @file_path + @image + '.tif'
      elsif @content == 'Images (TIFFs and JP2s)'
        archival_master_file_path = Settings.tmppath + SecureRandom.uuid + '.tif'
        #FileUtils.copy @file_path + 'Archive_TIFFs/' + image + '.tif', archival_master_file_path
        #@display_file_path = Settings.tmppath + SecureRandom.uuid + '.jp2'
        #FileUtils.copy @file_path + 'Dissemination_JPEG2000s/' + image + '.jp2', display_file_path
        @archival_master_file_path = @file_path + 'Archive_TIFFs/' + @image + '.tif'
        @display_file_path = @file_path + 'Dissemination_JPEG2000s/' + @image + '.jp2'
      end
    rescue
      @report << paragraph("ERROR in write_data_files #{$!}")
    end
  end

  def write_workflow_files
    wf_client_file_path = Settings.tmppath + SecureRandom.uuid + '.wf.client'
    File.open(wf_client_file_path, "w+") do |f|
      f.write(get_workflow_client_thesis_xml.to_xml)
    end
    #cleanup(metadata_file_path, wf_client_file_path, archival_master_file_path, display_file_path)
  end

  # Use default collection specified in settings unless otherwise specified
  def get_workflow_client_thesis_xml
    if @parent.nil? || @parent == ''
      @parent = Settings.thesis.parentcollection
    end
    builder = Nokogiri::XML::Builder.new do |xml|
      xml['wf'].workflow('xmlns:wf' => 'http://dlib.york.ac.uk/workflow') {
        xml['wf'].client(:scenarioid => Settings.image.scenarioid, :parent => @parent, :submittedBy => Settings.thesis.submittedBy, :client => Settings.thesis.client, :stopOnError => Settings.thesis.stopOnError, :accesskey => Settings.thesis.accesskey) {
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

  def cleanup
    if !@metadata_file_path.nil?
      if File.exist?(@metadata_file_path)
        FileUtils.rm @metadata_file_path
      end
    end
    if !@wf_client_file_path.nil?
      if File.exist?(@wf_client_file_path)
        FileUtils.rm @wf_client_file_path
      end
    end
    if !@archival_master_file_path.nil?
      if File.exist?(@archival_master_file_path)
        FileUtils.rm @archival_master_file_path
      end
    end
    if !@display_file_path.nil?
      if File.exist?(@display_file_path)
        FileUtils.rm @display_file_path
      end
    end
  end

  def paragraph(value)
    content_tag(:p, value).html_safe
  end
end