class VraDatastream < ActiveFedora::OmDatastream

  set_terminology do |t|
    t.root(:path => "vra", :xmlns => 'http://dlib.york.ac.uk/vra4york')
    t.image(:path => "image", :namespace_prefix => 'vra') {
      t.agentset(:path => "agentSet", :namespace_prefix => 'vra') {
        t.agent(:path => "agent", :namespace_prefix => 'vra') {
          t.role(:path => "role", :namespace_prefix => 'vra', attributes: { href: 'http://www.loc.gov/loc.terms/relators/PHT', vocab: 'http://www.loc.gov/loc.terms/relators/' })
          t.name(:path => "name", :namespace_prefix => 'vra')
        }
      }
      t.rightsset(:path => "rightsSet", :namespace_prefix => 'vra') {
        t.rights(:path => "rights", :namespace_prefix => 'vra') {
          t.rightshref(path: { attribute: "href" })
          t.text(:path => "text", :namespace_prefix => 'vra')
          t.rightsholder(:path => "rightsHolder", :namespace_prefix => 'vra')
        }
      }
      t.titleset(:path => "titleSet", :namespace_prefix => 'vra') {
        t.title(:path => "title", :namespace_prefix => 'vra')
      }
      t.worktypeset(:path => "worktypeSet", :namespace_prefix => 'vra') {
        t.worktype(:path => "worktype", :namespace_prefix => 'vra')
      }
    }
    t.work(:path => "work", :namespace_prefix => 'vra') {

      t.workhref(path: { attribute: "href" })
      t.workid(path: { attribute: "id" })
      t.refid(path: { attribute: "refid" })
      t.descriptionset(:path => "descriptionSet", :namespace_prefix => 'vra') {
        t.description(:path => "description", :namespace_prefix => 'vra')
      }
      t.locationset(:path => "locationSet", :namespace_prefix => 'vra') {
        t.location(:path => "location", attributes: { type: "repository" }, :namespace_prefix => 'vra') {
          t.name(:path => "name", attributes: { type: "corporate" }, :namespace_prefix => 'vra')
          t.gname(:path => "name", attributes: { type: "geographic" }, :namespace_prefix => 'vra')
          t.refid(:path => "refid", attributes: { type: "accession" }, :namespace_prefix => 'vra')
        }
      }
      t.titleset_(:path => "titleSet", :namespace_prefix => 'vra') {
        t.title(:path => "title", :namespace_prefix => 'vra') {
          t.lang(path: { attribute: "xml:lang" })
        }
      }
      t.worktypeset(:path => "worktypeSet", :namespace_prefix => 'vra') {
        t.worktype(:path => "worktype", :namespace_prefix => 'vra') {
          t.vocab(path: { attribute: "type" })
        }
      }
    }
  end

  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.vra("xmlns" => "http://dlib.york.ac.uk/vra4york",
              "xmlns:vra" => "http://dlib.york.ac.uk/vra4york",
              "xmlns:xsi" => 'http://www.w3.org/2001/XMLSchema-instance',
              "xsi:schemaLocation" => 'http://dlib.york.ac.uk/vra4york http://dlib.york.ac.uk/vra-4.0-restricted-york.xsd') {}
    end
    return builder.doc
  end

end