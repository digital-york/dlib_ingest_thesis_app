require 'csv'
require 'nokogiri'
require 'nokogiri-pretty'
require 'dotenv'
include ActionView::Helpers::TagHelper
include ActionView::Context

class IngestRun

  ALLOWED_HEADERS = ['dc:title', 'dc:identifier', 'dc:contributor', 'dc:creator', 'dc:publisher', 'dc:type', 'dc:format', 'dc:rights', 'dc:coverage', 'dc:language', 'dc:source', 'dc:description', 'dc:subject', 'dc:relation', 'dc:date', 'dc:contributor','parent', 'main', 'additional']
  IMAGE_HEADERS = ['image', 'folio', 'recto/verso', 'notes', 'worktype', 'parent', 'part', 'uv'] #no longer using description

  def ingest(folder, file, content, rights, filestore, parent, worktype, photographer, repository, dryrun, email)
    @folder = folder
    @file = file
    @content = content
    @rights = rights
    @filestore = filestore
    @parent = parent
    @worktype = worktype
    @photo = photographer
    @repository = repository
    @report = ''
    @stop = false
    @corrections = false
    @dir = true

    if dryrun
      # create a copy of the file
      begin
        #delete if we have an artefact file
        #FileUtils.rm(Settings.tmppath + email + '.csv')
        #causes an error
      rescue
        @report << paragraph("ERROR:#{$!}")
      end
      FileUtils.cp(@file, Settings.tmppath + email + '.csv')
      # do the dry run
      do_dryrun
      # return the report
      return @report.html_safe
    else
      @report << paragraph("Depending on the quantity and type of items you just ingested, it may take some time to process. Please check the parent collection on YODL and notify us if you spot any issues")
      @report << paragraph("The files you uploaded will be removed from their current location and moved to the server. If you have any 'leftover' that suggests a problem with that line in the spreadsheet.")
      #do the ingest
      if @content.start_with? "Image"
        @report = IngestImages.new.do_ingest(set_file_path, @folder, @content, @rights, @parent, @worktype, @photographer, @repository, email)
      else
        @report = IngestItems.new.do_ingest(set_file_path, @content, @rights, @parent, @repository, email)
      end
      # return the report
      @report.html_safe
    end

  end

  def do_dryrun
    @report << header("You Selected")
    @report << paragraph("Content: #{@content}")
    @report << paragraph("Parent: #{@parent}")
    @report << paragraph("Rights: #{@rights}")
    if @content.start_with? "Image"
      @report << paragraph("Photographer: #{@photo}")
      @report << paragraph("Worktype: #{@worktype}")
    end
    @report << paragraph("Repository: #{@repository}")
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
      @report << paragraph(" #{@file_path} exists.", 'tick')
    else
      @report << paragraph(" #{@file_path} does not exist.", 'tick')
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
        @report << paragraph(" File is valid CSV", 'tick')
        data = CSV.table(@file)
      rescue
        @report << paragraph(" File is not valid CSV. ERROR: #{$!}", 'cross')
        @corrections = true
        @stop = true
      end
      begin
        col = data[:parent]
        unless col.length == 1
          col = col.uniq
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
        @stop = true
      end
    end
  end

  def test_pid(value)
    require 'faraday'
    begin
      conn = Faraday.new(:url => Settings.server) do |c|
        c.use Faraday::Request::UrlEncoded # encode request params as "www-form-urlencoded"
        c.use Faraday::Response::Logger # log request & response to STDOUT
        c.use Faraday::Adapter::NetHttp # perform requests with Net::HTTP
      end
      # do basic auth
      conn.basic_auth(ENV['LIBARCHSTAFF_U'], ENV['LIBARCHSTAFF_P'])
      # do get
      response = conn.get '/fedora/objects/' + value
      if response.status == 200 # OK although this does not guarantee it's a collection
        @report << paragraph("Parent (#{value}) collection exists", 'tick')
      else # Fedora: 403 NOTAPPLICABLE
        @report << paragraph(" Parent (#{value}) collection not found. STATUS: #{response.status}", 'cross')
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
    content_tag(:span) {
      i = ''
      if (value == 'main' || value == 'additional') and @content == 'Collections'
        i << tag("img", src: 'assets/cross.png', alt: 'cross')
        i << ' this column will not be processed'
      elsif @content.start_with? 'Image' and IMAGE_HEADERS.include? value.downcase
        i << tag("img", src: 'assets/tick.png', alt: 'cross')
        i << ' This column will be processed'
      elsif ALLOWED_HEADERS.include? value.downcase
        i << tag("img", src: 'assets/tick.png', alt: 'cross')
        i << ' This column will be processed'
      else
        i << tag("img", src: 'assets/cross.png', alt: 'cross')
        i << ' This column will not be processed'
      end
      i.html_safe
    }.html_safe
  end

  def check_files
    if @dir
      @report << header("Check files")

      begin
        data = CSV.table(@file)
      rescue
        @report << paragraph("ERROR: #{$!}")
        @corrections = true
        @stop = true
      end
      if @content == 'Images'
        begin
          col = data[:image]
          col.each do |c|
            # we don't report on nil values
            unless c.to_s == '' || c.nil?
              if Dir.exist? @file_path
                file_exist(c, @folder.gsub('/', '') + '_JPEG2000s/', '.jp2')
              end
              file_exist(c, @folder.gsub('/', '') + '_TIFFs/', '.tif')
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
      unless @report.include? ' Cannot find'
        @report << paragraph("All files found")
      end
    end
  end

  def file_exist(file, added_path='', file_end='')
    # does file exist?
    unless File.exist? "#{@file_path}#{added_path}#{file}#{file_end}"
      @report << paragraph(" Cannot find #{@file_path}#{added_path}#{file}#{file_end}", 'cross')
      @corrections = true
    end
  end

  def stop_go
    @report << header("Summary")
    if @corrections
      @report << paragraph(" There are problems with the ingest, please review and correct these and then try again.", 'error')
    else
      @report << paragraph("Please review the report. If you are satisfied click the button below to proceed with the ingest.")
      @report << content_tag(:div, :class => "pretty_button") { content_tag(:a, "INGEST!", href: "/ingests/ingest_repost") }.html_safe
    end
  end

  def paragraph(value, icon=nil)
    content_tag(:p) {
      i = ''
      unless icon.nil?
        i << tag("img", src: 'assets/' + icon + '.png', alt: icon)
      end
      i << value
      i.html_safe
    }.html_safe
  end

  def header(value)
    content_tag(:h2, value).html_safe
  end

  def table(hash)
    if @content.start_with? "Image"
      unless hash.include? 'image' or hash.include? 'Image'
        @report << paragraph("There must be a column called 'image'.", 'cross')
        @corrections = true
      end
    end
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