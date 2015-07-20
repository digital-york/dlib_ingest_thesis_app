class DcDatastream < ActiveFedora::OmDatastream

    set_terminology do |t|
      t.root(:path=>"dc")
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
         xml['oai_dc'].dc('xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
                "xmlns:dc"=>"http://purl.org/dc/elements/1.1/") { }
       end
       return builder.doc
      #builder.to_xml
     end

end