require 'csv'
require 'nokogiri'
require 'nokogiri-pretty'
require 'dotenv'
include ActionView::Helpers::TagHelper
include ActionView::Context
require 'activemessaging'
include ActiveMessaging::MessageSender

class IngestItems

  def do_ingest(filepath, content, rights, parent, repository, email)
    @report = ''
    @file_path = filepath
    @content = content
    @rights = rights
    if parent.start_with?('york:')
      @parent = parent
    else
      @parent = 'york:'+ parent
    end
    @repository = repository
    @wf = nil # workflow xml
    @scenario = ''
    # open the stored file
    begin
      @file = File.open(Settings.tmppath + email + '.csv')
    rescue
      @report << paragraph("ERROR:#{$!}")
    end
    open_file
    process_file
    return @report
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
      group.each do | i |
        @additional_files = []
        begin
          @title = ''
          @file_output = DcDatastream.new
          i.each do |pair|
            build_metadata_from_file(pair)
          end
          build_content_type
          build_rights
          if @repository == 'borthwick' #skip the none
            @file_output.publisher += [Settings.repository.borthwick.name]
          end
          write_metadata_file
          write_data_files
          write_workflow_files
          # publish to the workflow queue
          @report << paragraph("Adding #{@title} to collection #{@parent}")
          publish :'workflow_queue', @wf, {'suppress_content_length' => true}
          count += 1
          #cleanup
        rescue
          @report << paragraph("ERROR line #{count + 1}:#{$!}")
        end
      end
      @report << paragraph("Processed #{count} line(s)")
    end
    return @report, @wf
  end

  def build_metadata_from_file(pair)
    case pair[0]
      when 'dc:title'
        @file_output.title += [pair[1]]
        @title += pair[1] + ' '
      when 'dc:identifier'
        @file_output.identifier += [pair[1]]
      when 'dc:contributor'
        @file_output.contributor += [pair[1]]
      when 'dc:creator'
        @file_output.creator += [pair[1]]
      when 'dc:publisher'
        @file_output.publisher += [pair[1]]
      when 'dc:type'
        @file_output.type += [pair[1]]
      when 'dc:format'
        @file_output.fmt += [pair[1]]
      when 'dc:rights'
        @file_output.rights += [pair[1]]
      when 'dc:coverage'
        @file_output.coverage += [pair[1]]
      when 'dc:language'
        @file_output.language += [pair[1]]
      when 'dc:source'
        @file_output.source += [pair[1]]
      when 'dc:description'
        @file_output.description += [pair[1]]
      when 'dc:subject'
        @file_output.subject += [pair[1]]
      when 'dc:relation'
        @file_output.relation += [pair[1]]
      when 'dc:date'
        @file_output.date += [pair[1]]
      when 'parent'
        if pair[1] != ''
          if pair[1].to_s.start_with?('york:')
            @parent = pair[1].to_s
          else
            @parent = 'york:' + pair[1].to_s
          end
        end
      # skip empty values
      when 'main'
        if pair[1] != nil
          @main_file = pair[1]
        end
      when 'additional'
        if pair[1] != nil
          @additional_files += [pair[1]]
        end
    end
  end

  def build_content_type # inject extra DC per content type
    case @content
      when 'Collections'
        @file_output.type += Settings.thesis.boiler_plate.dc_type_coll.to_hash.values
        @scenario = Settings.collection.scenarioid
      when 'Exam papers'
        @file_output.type += Settings.thesis.boiler_plate.dc_type_exam.to_hash.values
        @scenario = Settings.exampaper.scenarioid
      when 'Scholarly texts'
        @file_output.type += Settings.thesis.boiler_plate.dc_type_schol.to_hash.values
        @scenario = Settings.schol.scenarioid
      when 'Theses'
        @file_output.type += Settings.thesis.boiler_plate.dc_type.to_hash.values
        @scenario = Settings.thesis.scenarioid
    end
  end

  def build_rights
    # inject rights
    case @rights
      when 'york_restricted'
        @file_output.rights += Settings.rights.york_restricted.to_hash.values
      when 'undetermined'
        @file_output.rights += Settings.rights.undetermined.to_hash.values
      when 'uk_copyright_permitted_acts'
        @file_output.rights += Settings.rights.uk_copyright_permitted_acts.to_hash.values
      when 'creative_commons_by_nc_sa'
        @file_output.rights += Settings.rights.creative_commons_by_nc_sa.to_hash.values
      when 'creative_commons_by_nc_sa_preview'
        @file_output.rights += Settings.rights.creative_commons_by_nc_sa_preview.to_hash.values
      when 'creative_commons_by_nc_nd'
        @file_output.rights += Settings.rights.creative_commons_by_nc_nd.to_hash.values
      when 'creative_commons_by_nc_nd_preview'
        @file_output.rights += Settings.rights.creative_commons_by_nc_nd_preview.to_hash.values
      when 'admin_only'
        @file_output.rights += Settings.rights.admin_only.to_hash.values
      when 'online_only'
        @file_output.rights += Settings.rights.online_only.to_hash.values
      when 'public_domain'
        @file_output.rights += Settings.rights.public_domain.to_hash.values
    end
  end

  def write_metadata_file
    @metadata_file_path = Settings.tmppath + SecureRandom.uuid + '.dc'
    File.open(@metadata_file_path, "w+") do |f|
      f.write(@file_output.to_xml)
    end
  end

  def write_data_files
    begin
      unless @main_file.nil? || @main_file == ''
        @main_file_path = @file_path + @main_file
        if @main_file.include? ' '
          FileUtils.mv @main_file_path,@main_file_path.gsub(' ','_')
        end
        
      end
      if @additional_files != [] || !@additional_files.nil?
        @additional_files_paths = []
        @additional_files.each do |i|
          if i.include? ' '
            FileUtils.mv @file_path + i,@file_path + i.gsub!(' ','_')
          end
          @additional_files_paths += [@file_path + i]
        end
      end
    rescue
      raise
    end
  end

  def write_workflow_files
    File.open(Settings.tmppath + SecureRandom.uuid + '.wf.client', "w+") do |f|
      @wf = get_workflow_client_thesis_xml(@metadata_file_path, @main_file_path, @additional_files_paths).to_xml
      f.write(@wf)
    end
  end

# Use default collection specified in settings unless otherwise specified
  def get_workflow_client_thesis_xml(metadata_file, main_file=nil, additional_files=nil)
    if @parent == '' or @parent.nil?
      @parent = Settings.thesis.parentcollection
    end
    Nokogiri::XML::Builder.new do |xml|
      xml['wf'].workflow('xmlns:wf' => 'http://dlib.york.ac.uk/workflow') {
        xml['wf'].client(:scenarioid => @scenario, :parent => @parent, :submittedBy => Settings.thesis.submittedBy, :client => Settings.thesis.client, :stopOnError => Settings.thesis.stopOnError, :accesskey => Settings.thesis.accesskey) {
          xml['wf'].file(:mime => 'text/xml', :id => 'DC', :file => metadata_file)
          unless main_file.nil?
            xml['wf'].file(:mime => 'application/pdf', :main => 'true', :storelocally => 'true', :file => main_file)
          end
          unless additional_files.nil?
            additional_files.each do |i|
              xml['wf'].file(:mime => 'application/pdf', :main => 'false', :storelocally => 'true', :file => i)
            end
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
    if !@additional_files_paths.nil?
      @additional_files_paths.each do |i|
        if File.exist?(i)
          FileUtils.rm i
        end
      end
    end
    if !@main_file_path.nil?
      if File.exist?(@main_file_path)
        FileUtils.rm @main_file_path
      end
    end
  end

  def paragraph(value)
    content_tag(:p, value).html_safe
  end

end