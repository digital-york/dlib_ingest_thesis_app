require 'csv'
require 'nokogiri'
require 'nokogiri-pretty'
require 'dotenv'
require 'activemessaging'
include ActiveMessaging::MessageSender

class IngestImages

  def open_file(folder, file, content, rights, photographer, worktype, repository, filestore, parent)
    #@dryrun = dryrun
    @dryrun = true
    file_path = ''
    if filestore == 'yodlprodingest'
      file_path = Settings.filestore.yodlprodingest + folder + '/'
    elsif filestore == 'archbishop'
      file_path = Settings.filestore.archbishop + folder + '/'
    end
    file_path.gsub! '//', '/'

    puts file

    begin
      f = open(file)
      csv = CSV.read(f, :headers => true)
      f.close
      if @dryrun
        # first check headers and report
        message = "Checking columns, those with a cross will be ignored:</ br>"
        headers = CSV.open(f, 'r') { |csv| csv.first }
        headers.each do |i|
          case
            when i == 'image'
              message += i.to_s + " (tick)</ br>"
            when i == 'folio'
              message += i.to_s + " (tick)</ br>"
            when i == 'recto/verso'
              message += i.to_s + " (tick)</ br>"
            when i == 'description'
              message += i.to_s + " (tick</ br>)"
            when i == 'notes'
              message += i.to_s + " (tick)</ br>"
            when i == 'worktype'
              message += i.to_s + " (tick)</ br>"
            when i == 'parent'
              message += i.to_s + " (tick)</ br>"
            else
              message += i.to_s + " (cross)</ br>"
          end
        end

        if headers.include?('image')
          message += "</ br>No column for 'image', so no files found</ br>"
        else

          #now check that the files exist
          message += "</ br>Checking files, cannot find those listed below:</ br>"

          csv.group_by { |row| row[''] }.values.each do |group|
            group.each do |i|
              i.each_with_index do |pair,index|
                if pair[0].downcase == 'image'
                  if pair[1].to_s == ''
                    message += "blank entry at row (#{index})</ br>"
                  else
                    if content == 'Images (TIFFs only)'
                      f = file_path + pair[1].to_s + '.tif'
                      if File.file?(f)
                      else
                        message += "#{f} at row (#{index})</ br>"
                      end
                    elsif content == 'Images (TIFFs and JP2s)'
                      f = file_path + 'Archive_TIFFs/' + pair[1].to_s + '.tif'
                      if File.file?(f)
                      else
                        message += "#{f} at row (#{index})</ br>"
                      end
                      f = file_path + 'Dissemination_JPEG2/' + pair[1].to_s + '.jp2'
                      if File.file?(f)
                      else
                        message += "#{f} at row (#{index})</ br>"
                      end
                    end
                  end
                end
              end
            end
          end
        end

      else
        #count,failed_lines = process_file(file_path, csv, content, rights, photographer, worktype, repository, parent)
        #message = count.to_s + ' line(s) processed.'
      end

    rescue
      #log this $!
      message = 'There was a problem processing your file.'
    end
    return message #,failed_lines
  end

  def process_file(file_path, csv, content, rights, photographer, worktype, repository, parent)
    count = 0
    failed_lines = {}
    csv.group_by { |row| row[''] }.values.each do |group|
      group.each do |i|
        begin
          file_output = VraDatastream.new
          title = ''
          refid = ''
          image = ''
          par = parent
          i.each do |pair|
            case pair[0].downcase
              when 'image'
                image = pair[1]
                title += pair[1][0..-6].gsub! '_', ' '
                refid = title
                title += ' '
              when 'folio'
                title += pair[1].to_s
              when 'recto/verso'
                title += pair[1].to_s
              when 'description'
                title += pair[1].to_s
              when 'notes'
                file_output.work.descriptionset.description = pair[1].to_s
              when 'parent'
                par = pair[1].to_s
              when 'worktype'
                file_output.work.locationset.location.refid = pair[1].to_s
            end
            title.gsub! '  ', ' '
            file_output.image.titleset.title = title
            file_output.work.titleset.title = title
            file_output.work.titleset.title.lang = 'en'

            if repository == 'borthwick' #skip the none
              file_output.work.locationset.location.name = [Settings.repository.borthwick.name]
              file_output.work.locationset.location.gname = [Settings.repository.borthwick.place]
            end

            file_output.work.locationset.location.refid = refid
          end

          file_output.image.agentset.agent.name = photographer
          file_output.image.agentset.agent.role = 'photographer'
          file_output.image.worktypeset.worktype = 'digital photograph or image'

          #we prefer what's in the file to the boilerplate
          if worktype != ''
            file_output.work.worktypeset.worktype = worktype
          end
          #we prefer what's in the file to the boilerplate
          if parent != ''
            par = parent
          end

          # inject rights
          case rights
            when 'york_restricted'
              file_output.image.rightsset.rights.text = Settings.rights.york_restricted.text
              file_output.image.rightsset.rights.rightshref = Settings.rights.york_restricted.license
            when 'undetermined'
              file_output.image.rightsset.rights.text = Settings.rights.undetermined.text
              file_output.image.rightsset.rights.rightshref = Settings.rights.undetermined.license
            when 'uk_copyright_permitted_acts'
              file_output.image.rightsset.rights.text = Settings.rights.uk_copyright_permitted_acts.text
              file_output.image.rightsset.rights.rightshref = Settings.rights.uk_copyright_permitted_acts.license
            when 'creative_commons_by_nc_sa'
              file_output.image.rightsset.rights.text = Settings.rights.creative_commons_by_nc_sa.text
              file_output.image.rightsset.rights.rightshref = Settings.rights.creative_commons_by_nc_sa.license
            when 'creative_commons_by_nc_sa_preview'
              file_output.image.rightsset.rights.text = Settings.rights.creative_commons_by_nc_sa_preview.text
              file_output.image.rightsset.rights.rightshref = Settings.rights.creative_commons_by_nc_sa_preview.license
            when 'creative_commons_by_nc_nd'
              file_output.image.rightsset.rights.text = Settings.rights.creative_commons_by_nc_nd.text
              file_output.image.rightsset.rights.rightshref = Settings.rights.creative_commons_by_nc_nd.license
            when 'creative_commons_by_nc_nd_preview'
              file_output.image.rightsset.rights.text = Settings.rights.creative_commons_by_nc_nd_preview.text
              file_output.image.rightsset.rights.rightshref = Settings.rights.creative_commons_by_nc_nd_preview.license
            when 'admin_only'
              file_output.image.rightsset.rights.text = Settings.rights.admin_only.text
              file_output.image.rightsset.rights.rightshref = Settings.rights.admin_only.license
            when 'online_only'
              file_output.image.rightsset.rights.text = Settings.rights.online_only.text
              file_output.image.rightsset.rights.rightshref = Settings.rights.online_only.license
            when 'public_domain'
              file_output.image.rightsset.rights.text = Settings.rights.public_domain.text
              file_output.image.rightsset.rights.rightshref = Settings.rights.public_domain.license
          end

          metadata_file_path = Settings.tmppath + SecureRandom.uuid + '.vra'
          File.open(metadata_file_path, "w+") do |f|
            f.write(file_output.to_xml)
          end

          begin
            if content == 'image (single TIFF)'
              archival_master_file_path = Settings.tmppath + SecureRandom.uuid + '.tif'
              FileUtils.copy file_path + image + '.tif', archival_master_file_path
            elsif content == 'image (TIFF master and JP2 display)'
              archival_master_file_path = Settings.tmppath + SecureRandom.uuid + '.tif'
              FileUtils.copy file_path + 'Archive_TIFFs/' + image + '.tif', archival_master_file_path
              display_file_path = Settings.tmppath + SecureRandom.uuid + '.jp2'
              FileUtils.copy file_path + 'Dissemination_JPEG2/' + image + '.jp2', display_file_path
            end
          rescue
            failed_lines[image] = 'could not find image file'
            raise
          end

          wf_client_file_path = Settings.tmppath + SecureRandom.uuid + '.wf.client'
          File.open(wf_client_file_path, "w+") do |f|
            f.write(get_workflow_client_thesis_xml(metadata_file_path, par, archival_master_file_path, display_file_path).to_xml)
          end

          #publish()
          #publish :'workflow_queue', get_workflow_client_thesis_xml(file_output, parent,main_file_path,additional_files_paths).to_xml, {'suppress_content_length' => true}
          count += 1
        rescue
          if !failed_lines.has_key?(image)
            failed_lines[image] = 'error'
          end
          #delete any files created during a failed process
          cleanup(metadata_file_path, wf_client_file_path, archival_master_file_path, display_file_path)
        end
      end
    end
    return count, failed_lines
  end

  # Use default collection specified in settings unless otherwise specified
  def get_workflow_client_thesis_xml(metadata_file, parent, master_file=nil, display_file=nil)
    if parent = ''
      parent = Settings.thesis.parentcollection
    end
    builder = Nokogiri::XML::Builder.new do |xml|
      xml['wf'].workflow('xmlns:wf' => 'http://dlib.york.ac.uk/workflow') {
        xml['wf'].client(:scenarioid => Settings.image.scenarioid, :parent => parent, :submittedBy => Settings.thesis.submittedBy, :client => Settings.thesis.client, :stopOnError => Settings.thesis.stopOnError, :accesskey => Settings.thesis.accesskey) {
          xml['wf'].file(:mime => 'text/xml', :id => 'VRA', :file => metadata_file)

          if !master_file.nil?
            xml['wf'].file(:mime => 'image/tiff', :storelocally => 'true', :file => master_file)
          end
          if !display_file.nil?
            xml['wf'].file(:mime => 'image/jp2', :storelocally => 'true', :file => display_file)
          end
        }
      }
    end
  end

  def cleanup(metadata_file_path, wf_client_file_path, archival_master_file_path, display_file_path)
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
    if !archival_master_file_path.nil?
      if File.exist?(archival_master_file_path)
        FileUtils.rm archival_master_file_path
      end
    end
    if !display_file_path.nil?
      if File.exist?(display_file_path)
        FileUtils.rm display_file_path
      end
    end
  end
end