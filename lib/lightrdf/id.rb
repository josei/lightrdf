module RDF
  module ID
    @count = 0
    @ns = { :rdf  => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
            :rdfs => 'http://www.w3.org/2000/01/rdf-schema#',
            :dc   => 'http://purl.org/dc/elements/1.1/',
            :owl  => 'http://www.w3.org/2002/07/owl#' }

    def self.ns;      @ns;      end
    def self.count;   @count;   end
    def self.count=c; @count=c; end

    def self.bnode? id
      id.to_s[0..0] == '_'
    end
    def self.uri? id
      !bnode?(id)
    end

    def self.parse id, ns={}
      if id.to_s[0..6]!='http://' and id.to_s[0..7]!='https://' and id.to_s[0..0]!='_' and id.to_s =~ /(\w+):(\w.*)/
        :"#{RDF::ID.ns.merge(ns)[$1.to_sym]}#{$2}"
      elsif id == '*' or !id
        :"_:bnode#{@count+=1}"
      else
        id.to_sym
      end
    end
  
    def self.compress uri, ns={}
      RDF::ID.ns.merge(ns).map.sort_by{|k,v| -v.to_s.size}.each do |k,v|
        if uri.to_s.index(v) == 0
          return "#{k}:#{uri.to_s[v.size..-1]}"
        end
      end
      uri.to_s
    end
  end
end

# Shortcut to parse IDs
def ID id, ns={}
  RDF::ID.parse id, ns
end
# Shortcut to declare namespaces
def Namespace prefix, uri
  RDF::ID.ns[prefix.to_sym] = uri
end
