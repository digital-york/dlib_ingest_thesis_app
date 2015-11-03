module CollectionsHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Context

  def get_collections_tree
    require 'faraday'

    begin

      conn = Faraday.new(:url => Settings.server) do |c|
        c.use Faraday::Request::UrlEncoded # encode request params as "www-form-urlencoded"
        c.use Faraday::Response::Logger # log request & response to STDOUT
        c.use Faraday::Adapter::NetHttp # perform requests with Net::HTTP
      end
      conn.basic_auth(ENV['LIBARCHSTAFF_U'], ENV['LIBARCHSTAFF_P'])

      response = conn.get '/yodl/api/resource/collections'

      # handle timeout here

      # conn = Faraday.new(:url => 'https://yodlapp3.york.ac.uk') do |faraday|
      #   faraday.use FaradayMiddleware::FollowRedirects  # follow redirects
      #   faraday.request  :url_encoded             # form-encode POST params
      #   faraday.use :cookie_jar                   # persist cookies across redirects
      #   #faraday.response :logger                 # log requests to STDOUT
      #   faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      # end
      #
      # response = conn.post do |req|
      #   req.url '/yodl/j_spring_security_check'
      #   req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      #   req.body = 'j_username=libArchStaff&j_password=libarchstaff&spring-security-redirect=%2Fapi%2Fresource%2Fcollections'
      # end

      content_tag(:p, "There was a problem loading the collections. The Digital Library may be unavailable.").html_safe
      unless response.body.include? 'Access denied- University of York Digital Library' || 'Service Temporarily Unavailable'
        doc = Nokogiri::XML(response.body)
        # create a hash from the xml
        hash = Hash.from_xml(doc.to_s)

        # loop down to the bit we want and build a http://www.jstree.com/
        hash.each do |key, array|
          array.each do |key, a|
            a.each do |key, i|
              if key == 'collection'
                return hash_list(i)
              end
            end
          end
        end
      end
      rescue
        content_tag(:p, "There was a problem loading the collections. The Digital Library may be unavailable.").html_safe
      end
    end

    private
    def hash_list(hash)

      html = content_tag(:div, :id => "html1") {
        output = ''
        hash.each do |child|
          output << content_tag(:ul, hash_li(child))
        end
        output.html_safe
      }.html_safe
    end

    # there is probably a more efficient way of doing this
    private
    def hash_ul(hash)
      output = ''
      if hash.class == Array
        hash.each do |i|
          if i["collection"].nil?
            output << content_tag(:ul, content_tag(:li, i["label"], :id => i["pid"]))
          else
            ul = content_tag(:li, :id => i["pid"]) do
              i["label"].html_safe + hash_ul(i["collection"])
            end
            output << content_tag(:ul, ul)
          end
        end
      else
      end
      output.html_safe
    end

    private
    def hash_li(hash)
      ul_contents = ""
      if hash.class == Hash
        if hash["collection"].nil?
          ul_contents << content_tag(:li, hash["label"], :id => hash["pid"])
        else
          ul = content_tag(:li, :id => hash["pid"]) do
            hash["label"].html_safe + hash_ul(hash["collection"])
          end
          ul_contents << ul
        end
        ul_contents.html_safe
      end
    end

  end