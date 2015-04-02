class DcDatastream < ActiveFedora::OmDatastream

    set_terminology do |t|
      t.root(:path=>"oai_dc", :xmlns=>'http://www.openarchives.org/OAI/2.0/oai_dc/')
      t.title(:path=>"title", :namespace_prefix => 'dc')
      t.contributor(:path=>"contributor", :namespace_prefix => 'dc')
      t.coverage(:path=>"coverage", :namespace_prefix => 'dc')
      t.creator(:path=>"creator", :namespace_prefix => 'dc')
      t.description(:path=>"description", :namespace_prefix => 'dc')
      t.fmt(:path=>"format", :namespace_prefix => 'dc')
      t.identifier(:path=>"identifier", :namespace_prefix => 'dc')
      t.language(:path=>"language", :namespace_prefix => 'dc')
      t.publisher(:path=>"publisher", :namespace_prefix => 'dc')
      t.relation(:path=>"relation", :namespace_prefix => 'dc')
      t.source(:path=>"source", :namespace_prefix => 'dc')
      t.subject(:path=>"subject", :namespace_prefix => 'dc')
      t.rights(:path=>"rights", :namespace_prefix => 'dc')
      t.type(:path=>"type", :namespace_prefix => 'dc')
      t.date(:path=>"date", :namespace_prefix => 'dc')
    end

    def self.xml_template
       builder = Nokogiri::XML::Builder.new do |xml|
         xml.oai_dc("xmlns"=>'http://www.openarchives.org/OAI/2.0/oai_dc/',
                "xmlns:dcterms"=>'http://purl.org/dc/terms/',
                "xmlns:dc"=>"http://purl.org/dc/elements/1.1/",
                "xmlns:xsi"=>'http://www.w3.org/2001/XMLSchema-instance') { }
       end
       return builder.doc
     end

end