require 'csv'
require 'nokogiri'
require 'nokogiri-pretty'
require 'dotenv'
include ActionView::Helpers::TagHelper
include ActionView::Context

class IngestRun

  ALLOWED_HEADERS = ['dc:title', 'dc:identifier', 'dc:contributor', 'dc:creator', 'dc:publisher', 'dc:type', 'dc:format', 'dc:rights', 'dc:coverage', 'dc:language', 'dc:source', 'dc:description', 'dc:subject', 'dc:relation', 'dc:date', 'parent', 'main', 'additional']
  IMAGE_HEADERS = ['image', 'folio', 'recto/verso', 'description', 'notes', 'worktype', 'parent']

  def ingest(folder, file, content, rights, filestore, parent, worktype, photographer, repository, dryrun, email)
    @folder = folder
    @file = file
    @content = content
    @rights = rights
    @filestore = filestore
    @parent = parent
    @worktype = worktype
    @photo = photographer
    @repo = repository
    @report = ''
    @stop = false
    @corrections = false
    @dir = true

    if dryrun
      # create a copy of the file
      begin
        FileUtils.rm(Settings.tmppath + email + '.csv')
      rescue
        @report << paragraph("ERROR:#{$!}")
      end
      FileUtils.cp(@file, Settings.tmppath + email + '.csv')
      # do the dry run
      do_dryrun
    else
      #do the ingest
      if @content.start_with? "Image"
        @report = IngestImages.new.do_ingest(set_file_path, @content, @rights, @parent, @worktype, @photographer, @repository, email)
      else
        @report = IngestItems.new.do_ingest(set_file_path, @content, @rights, @parent, @repository, email)
      end
    end
    # return the report
    @report.html_safe
  end

  def do_dryrun
    @report << header("You Selected")
    @report << paragraph("Content: #{@content}")
    @report << paragraph("Parent: #{@parent}")
    @report << paragraph("Rights: #{@rights}")
    @report << paragraph("Photographer: #{@photo}")
    @report << paragraph("Worktype: #{@worktype}")
    @report << paragraph("Repository: #{@repo}")
    if @content == 'Collections'
      @report << paragraph("You selected #{@content}, no files will be processed in the ingest.")
    else
      dir_exist
    end
    check_parents
    unless @stop
      check_headers
      unless @content == 'Collections'
        check_files
      end
    end
    stop_go
  end

  def dir_exist
    # does file path exist?
    @report << header("Does the directory exist?")
    if Dir.exist? set_file_path
      @report << paragraph("TICK #{@file_path} exists.")
    else
      @report << paragraph("CROSS #{@file_path} does not exist.")
      @corrections = true
      @dir = false
    end
  end

  def set_file_path
    @file_path = ''
    if @filestore == 'yodlprodingest'
      @file_path = "#{Settings.filestore.yodlprodingest}#{@folder}/"
    elsif @filestore == 'archbishop'
      @file_path = Settings.filestore.archbishop + @folder + '/'
    end
    # just in case we have received extra slashes
    @file_path.gsub! '//', '/'
    @file_path
  end

  def check_parents
    @report << header("Check parent collections")
    unless @parent.nil? || @parent == ''
      # deal with pids with or without the namespace
      if @parent.start_with?('york:')
        test_pid(@parent)
      else
        test_pid('york:'+@parent)
      end
    else
      #grab the parents list in the csv file and go through unique values
      begin
        @report << paragraph("TICK File is valid CSV")
        data = CSV.table(@file)
      rescue
        @report << paragraph("CROSS File is not valid CSV. ERROR: #{$!}")
        @corrections = true
        @stop = true
      end
      begin
        col = data[:parent]
        unless col.length == 1
          col = col.uniq!
        end
        col.each do |c|
          # we don't report on nil values, it's possible that there is no parent for some
          unless c.to_s == '' || c.nil?
            if c.to_s.start_with?('york:')
              test_pid(c.to_s)
            else
              test_pid('york:'+c.to_s)
            end
          end
        end
      rescue
        @report << paragraph("ERROR: #{$!}")
        @corrections = true
      end
    end
  end

  def test_pid(value)
    require 'faraday'
    begin
      conn = Faraday.new(:url => 'http://yodlapp3.york.ac.uk') do |c|
        c.use Faraday::Request::UrlEncoded # encode request params as "www-form-urlencoded"
        c.use Faraday::Response::Logger # log request & response to STDOUT
        c.use Faraday::Adapter::NetHttp # perform requests with Net::HTTP
      end
      # do basic auth
      conn.basic_auth(ENV['LIBARCHSTAFF_U'], ENV['LIBARCHSTAFF_P'])
      # do get
      response = conn.get '/fedora/objects/' + value
      if response.status == 200 # OK although this does not guarantee it's a collection
        @report << paragraph("TICK Parent (#{value}) collection exists")
      else # Fedora: 403 NOTAPPLICABLE
        @report << paragraph("CROSS Parent (#{value}) collection not found. STATUS: #{response.status}")
        @corrections = true
      end
    rescue
      @report << paragraph("ERROR: #{$!}")
      @stop = true
    end
  end

  def check_headers
    begin
      @report << header("Check CSV file column headers")
      CSV.foreach(@file) do |header|
        if $. == 1
          begin
            @report << table(header)
          rescue
            @report << paragraph("An unexpected error occured when processing the headers. ERROR: #{$!}")
            @stop = true
          end
        end
      end
    rescue
      @report << paragraph("ERROR: #{$!}")
      @stop = true
    end
  end

  def allowed(value)
    if (value == 'main' || value == 'additional') and @content == 'Collections'
      'CROSS this column will not be processed'
    elsif @content.start_with? 'Image' and IMAGE_HEADERS.include? value.downcase
      'TICK this column will be processed'
    elsif ALLOWED_HEADERS.include? value.downcase
      'TICK this column will be processed'
    else
      'CROSS this column will not be processed'
    end
  end

  def check_files
    if @dir
      @report << header("Check files (only reports if they are not found)")

      begin
        data = CSV.table(@file)
      rescue
        @report << paragraph("ERROR: #{$!}")
        @corrections = true
        @stop = true
      end
      if @content == 'Images (TIFFs only)'
        begin
          col = data[:image]
          col.each do |c|
            # we don't report on nil values
            unless c.to_s == '' || c.nil?
              file_exist(c, '', '.tiff')
            end
          end
        rescue
          @report << paragraph("ERROR: #{$!}")
        end
      elsif @content == 'Images (TIFFs and JP2s)'
        begin
          col = data[:image]
          col.each do |c|
            # we don't report on nil values
            unless c.to_s == '' || c.nil?
              file_exist(c, 'Dissemination_JPEG2000s/', '.jp2')
              file_exist(c, 'Archive_TIFFs/', '.tif')
            end
          end
        rescue
          @report << paragraph("ERROR: #{$!}")
        end
      else
        begin
          col = data[:main]
          col.each do |c|
            # we don't report on nil values, it's possible that there is no main for some
            unless c.to_s == '' || c.nil?
              file_exist(c)
            end
          end
        rescue
          @report << paragraph("ERROR: #{$!}")
          @corrections = true
        end
        begin
          data.each_with_index do |row, i|
            (0...data.headers.length).each do |j|
              if data.headers[j] == :additional
                file_exist(row[j])
              end
            end
          end
        rescue
        @report << paragraph("ERROR: #{$!}")
        @corrections = true
      end
    end
  end
end

def file_exist(file, added_path='', file_end='')
  # does file exist?
  unless File.exist? "#{@file_path}#{added_path}#{file}#{file_end}"
    @report << paragraph("CROSS Cannot find #{@file_path}#{added_path}#{file}#{file_end}")
    @corrections = true
  end
end

def stop_go
  @report << header("Summary")
  if @corrections
    @report << paragraph("There are problems with the ingest, please review and correct these and then try again.")
  else
    @report << paragraph("Please review the report. If you are satisfied click the button below to proceed with the ingest.")
    @report << content_tag(:div, :class => "pretty_button") { content_tag(:a, "INGEST!", href: "/ingests/ingest_repost") }.html_safe
  end
end

def paragraph(value)
  content_tag(:p, value).html_safe
end

def header(value)
  content_tag(:h2, value).html_safe
end

def table(hash)
  @num_additional = 0
  content_tag(:table) {
    output = ''
    hash.each do |child|
      if child == 'additional'
        @num_additional += 1
      end
      row = ''
      row << content_tag(:td, child)
      row << content_tag(:td, allowed(child))
      output << content_tag(:tr) << row
    end
    output.html_safe
  }.html_safe
end


end