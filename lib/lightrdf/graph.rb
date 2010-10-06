module RDF
  class Graph < Hash
    include Parser
    # Namespace set stored when parsing a file. Can be used for reference
    attr_accessor :ns
    def initialize triples=[]
      super(nil)
      @ns = {}
      self.triples = triples
    end

    def << node
      self[node] = node
    end

    def [] id
      super(ID(id)) || Node.new(id, self)
    end
    def []= id, node
      node.graph = self
      super ID(id), node
    end
    def nodes; values; end
    def inspect
      "{" + (values.map{|v| v.inspect} * ", ") + "}"
    end
    def merge graph
      new_graph = Graph.new
      new_graph.triples = triples + graph.triples
      new_graph
    end
    def triples
      triples = []; values.each { |n| triples += n.triples }
      triples
    end
    def triples= triples
      self.clear
      triples.each { |s, p, o| self[s][p] = self[s][p] + [o] }
    end
    
    def find subject, predicate, object
      matches = triples.select { |s,p,o| (subject.nil? or subject==[] or s==subject) and
                                         (predicate.nil? or predicate==[] or p==predicate) and
                                         (object.nil? or object==[] or o==object) }
      result = []
      result += matches.map {|t| t[0] } if subject.nil?
      result += matches.map {|t| t[1] } if predicate.nil?
      result += matches.map {|t| t[2] } if object.nil?
      result.uniq
    end
  end
end
