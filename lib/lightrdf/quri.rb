module RDF
  module QURI
    @ns = { :rdf  => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
            :rdfs => 'http://www.w3.org/2000/01/rdf-schema#',
            :dc   => 'http://purl.org/dc/elements/1.1/',
            :owl  => 'http://www.w3.org/2002/07/owl#' }
    def self.ns; @ns; end

    def self.parse uri, ns={}
      URI.parse( (uri.to_s =~ /(\w+):(.*)/ and uri.to_s[0..6]!='http://' and uri.to_s[0..7]!='https://') ?
                  "#{QURI.ns.merge(ns)[$1.to_sym]}#{$2}" :
                  uri.to_s )
    end

    def self.compress uri, ns={}
      QURI.ns.merge(ns).map.sort_by{|k,v| -v.to_s.size}.each do |k,v|
        if uri.to_s.index(v) == 0
          return "#{k}:#{uri.to_s[v.size..-1]}"
        end
      end
      uri.to_s
    end
  end

  module ID
    def self.ns; QURI.ns; end

    def compressed ns={}
      RDF::ID.compress self, ns
    end

    def self.compress id, ns={}
      bnode?(id) ? id.to_s : RDF::QURI.compress(id, ns)
    end

    def self.parse id, ns={}
      bnode?(id) ? RDF::BNodeID.parse(id) : RDF::QURI.parse(id, ns)
    end

    def self.bnode?(id)
      id.nil? or id == '*' or id.to_s[0..0] == '_'
    end
  end

  class BNodeID
    include RDF::ID
    @count = 0
    def self.count; @count; end
    def self.count=c; @count=c; end

    attr_reader :id
    def initialize id=nil
      @id = (id || "_:bnode#{RDF::BNodeID.count+=1}").to_s
    end
    def self.parse id
      new(id=='*' ? nil : id)
    end
    def to_s; id.to_s; end

    def == b
      eql? b
    end
    def eql? b
      b.is_a?(BNodeID) and self.id == b.id
    end
    def hash # Hack for Ruby 1.8.6
      id.hash + self.class.hash
    end
  end
end

class URI::Generic
  include RDF::ID # URIs are RDF IDs
end

def ID uri, ns={} # Shortcut to parse IDs
  RDF::ID.parse uri, ns
end
def Namespace prefix, uri
  RDF::QURI.ns[prefix.to_sym] = uri
end
