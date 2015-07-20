require 'csv'
require 'nokogiri'
require 'nokogiri-pretty'
require 'dotenv'
require 'activemessaging'
include ActiveMessaging::MessageSender

class IngestItems

  def open_file(folder, file, content, rights, filestore, parent)
    file_path = ''
    if filestore == 'yodlprodingest'
      file_path = Settings.filestore.yodlprodingest + folder + '/'
    elsif filestore == 'archbishop'
      file_path = Settings.filestore.archbishop + folder + '/'
    end
    file_path.gsub! '//', '/'
    begin
      f = open(file)
      csv = CSV.read(f, :headers => true)
      f.close
      count, failed_lines = process_file(file_path, csv, content, rights, parent)
      message = count.to_s + ' line(s) processed.'
      rescue => error
      puts error
      message = 'There was a problem processing your file. Is it a valid CSV file?'
    end
    return message, failed_lines
  end

  def process_file(file_path, csv, content, rights, parent)
    additional_files = []
    count = 0
    failed_lines = {}
    main_file = ''
    additional_files = []
    csv.group_by { |row| row[''] }.values.each do |group|
      group.each do |i|
        begin
          title = ''
          file_output = DcDatastream.new
          i.each do |pair|
            case pair[0]
              when 'dc:title'
                file_output.title += [pair[1]]
                title += pair[1] + ' '
              when 'dc:identifier'
                file_output.identifier += [pair[1]]
              when 'dc:contributor'
                file_output.contributor += [pair[1]]
              when 'dc:creator'
                file_output.creator += [pair[1]]
              when 'dc:publisher'
                file_output.publisher += [pair[1]]
              when 'dc:type'
                file_output.type += [pair[1]]
              when 'dc:format'
                file_output.fmt += [pair[1]]
              when 'dc:rights'
                file_output.rights += [pair[1]]
              when 'dc:coverage'
                file_output.coverage += [pair[1]]
              when 'dc:language'
                file_output.language += [pair[1]]
              when 'dc:source'
                file_output.source += [pair[1]]
              when 'dc:description'
                file_output.description += [pair[1]]
              when 'dc:subject'
                file_output.subject += [pair[1]]
              when 'dc:relation'
                file_output.relation += [pair[1]]
              when 'dc:date'
                file_output.date += [pair[1]]
              when 'parent'
                if pair[1] != ''
                  parent = pair[1]
                end
              when 'main'
                if pair[1] != nil
                  main_file = pair[1]
                end
              when 'additional'
                if pair[1] != nil
                  additional_files += [pair[1]]
                end
            end
          end

          # inject extra DC per content type
          case content
            when 'Collection'
              file_output.type += Settings.thesis.boiler_plate.dc_type_coll.to_hash.values
            when 'Exam Paper'
              file_output.type += Settings.thesis.boiler_plate.dc_type_exam.to_hash.values
            when 'Scholarly Text'
              file_output.type += Settings.thesis.boiler_plate.dc_type_schol.to_hash.values
            when 'Thesis'
              file_output.type += Settings.thesis.boiler_plate.dc_type.to_hash.values
          end

          # inject rights
          # inject rights
          case rights
            when 'york_restricted'
              file_output.rights += Settings.rights.york_restricted.to_hash.values
            when 'undetermined'
              file_output.rights += Settings.rights.undetermined.to_hash.values
            when 'uk_copyright_permitted_acts'
              file_output.rights += Settings.rights.uk_copyright_permitted_acts.to_hash.values
            when 'creative_commons_by_nc_sa'
              file_output.rights += Settings.rights.creative_commons_by_nc_sa.to_hash.values
            when 'creative_commons_by_nc_sa_preview'
              file_output.rights += Settings.rights.creative_commons_by_nc_sa_preview.to_hash.values
            when 'creative_commons_by_nc_nd'
              file_output.rights += Settings.rights.creative_commons_by_nc_nd.to_hash.values
            when 'creative_commons_by_nc_nd_preview'
              file_output.rights += Settings.rights.creative_commons_by_nc_nd_preview.to_hash.values
            when 'admin_only'
              file_output.rights += Settings.rights.admin_only.to_hash.values
            when 'online_only'
              file_output.rights += Settings.rights.online_only.to_hash.values
            when 'public_domain'
              file_output.rights += Settings.rights.public_domain.to_hash.values
          end

          if rights == 'york_restricted'
            file_output.rights += Settings.thesis.boiler_plate.dc_rights.york_restricted.to_hash.values
          elsif rights == 'creative_commons_by_nc_nd'
            file_output.rights += Settings.thesis.boiler_plate.dc_rights.public_rights.to_hash.values
          end

          metadata_file_path = Settings.tmppath + SecureRandom.uuid + '.dc'
          File.open(metadata_file_path, "w+") do |f|
            f.write(file_output.to_xml)
          end

          begin
            if main_file != '' and !main_file.nil?
              main_file_path = file_path + main_file
            end
            if additional_files != [] and !additional_files.nil?
              additional_files_paths = []
              additional_files.each do |i|
                additional_files_paths += [file_path + i]
              end
            end
          rescue => error
            failed_lines[title] = 'could not find file'
            puts error
            raise
          end
          wf_client_file_path = Settings.tmppath + SecureRandom.uuid + '.wf.client'

          File.open(wf_client_file_path, "w+") do |f|
            f.write(get_workflow_client_thesis_xml(metadata_file_path, parent, main_file_path, additional_files_paths).to_xml)
          end

          #publish to the workflow queue
          publish :'workflow_queue', get_workflow_client_thesis_xml(metadata_file_path, parent,main_file_path,additional_files_paths).to_xml, {'suppress_content_length' => true}
          count += 1
        rescue => error
          puts error
          if !failed_lines.has_key?(title)
            failed_lines[title] = 'error'
          end
          #cleanup(metadata_file_path, wf_client_file_path, additional_files_paths, main_file_path)
        end
      end
    end
    return count, failed_lines
  end

  # Use default collection specified in settings unless otherwise specified
  def get_workflow_client_thesis_xml(metadata_file, parent, main_file=nil, additional_files=nil)
    if parent == '' or parent.nil?
      parent = Settings.thesis.parentcollection
    end
    builder = Nokogiri::XML::Builder.new do |xml|
      xml['wf'].workflow('xmlns:wf' => 'http://dlib.york.ac.uk/workflow') {
        xml['wf'].client(:scenarioid => Settings.thesis.scenarioid, :parent => parent, :submittedBy => Settings.thesis.submittedBy, :client => Settings.thesis.client, :stopOnError => Settings.thesis.stopOnError, :accesskey => Settings.thesis.accesskey) {
          xml['wf'].file(:mime => 'text/xml', :id => 'DC', :file => metadata_file)
          if !main_file.nil?
            xml['wf'].file(:mime => 'application/pdf', :main => 'true', :storelocally => 'true', :file => main_file)
          end
          if !additional_files.nil?
            additional_files.each do |i|
              xml['wf'].file(:mime => 'application/pdf', :main => 'false', :storelocally => 'true', :file => i)
            end
          end
        }
      }
    end
  end

  def cleanup(metadata_file_path, wf_client_file_path, additional_files_paths, main_file_path)
    if !metadata_file_path.nil?
      if File.exist?(metadata_file_path)
        FileUtils.rm metadata_file_path
      end
    end
    if !wf_client_file_path.nil?
      if File.exist?(wf_client_file_path)
        FileUtils.rm wf_client_file_path
      end
    end
    if !additional_files_paths.nil?
      additional_files_paths.each do | i |
        if File.exist?(i)
          FileUtils.rm i
        end
      end
    end
    if !main_file_path.nil?
      if File.exist?(main_file_path)
        FileUtils.rm main_file_path
      end
    end
  end
end