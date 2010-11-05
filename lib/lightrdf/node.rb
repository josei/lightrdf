module RDF
  class NsProxy
    if RUBY_VERSION < '1.9'
      undef :type
      undef :id
    end
    undef :class
    def initialize ns, object
      @object = object
      @ns = ns
    end
    def method_missing method, *args
      if method.to_s =~ /.*=\Z/
        @object["#{@ns}:#{method.to_s[0..-2]}"] = args.first
      elsif method.to_s =~ /.*\?\Z/
        @object["#{@ns}:#{method.to_s[0..-2]}"].include?(args.first)
      else
        @object["#{@ns}:#{method}"]
      end
    end
  end

  class Node < Hash
    include Parser
    attr_accessor :graph, :id

    def initialize id=nil, graph=nil
      @id = ID::parse(id)
      @graph = graph || Graph.new
      @graph << self
    end

    def method_missing method, *args
      QURI.ns[method] ? NsProxy.new(method, self) : super
    end
    def inspect; "<#{self.class} #{id} #{super}>"; end
    def to_s; id.to_s; end

    def [] name
      self[Node(name)] = [] if super(Node(name)).nil?
      super(Node(name)).map! {|n| n.is_a?(Node) ? @graph[n] : n}
    end
    def []= name, values
      super(Node(name), [values].flatten.map { |node| node.is_a?(Node) ? @graph[node] : node })
    end

    def == b
      eql? b
    end
    def eql? b
      b.is_a?(Node) and self.id == b.id
    end
    def hash # Hack for Ruby 1.8.6
      id.hash ^ self.class.hash
    end

    def predicates
      keys.map { |p| [ @graph[p], self[p] ] }
    end

    def triples
      triples = []; each { |k, v| v.each { |o| triples << [self, Node(k), o] } }
      triples
    end
    
    def merge node
      new_node = clone
      (self.keys + node.keys).uniq.each do |k|
        new_node[k] = (node[k] + self[k]).uniq
      end
      new_node
    end

    def clone
      Node.new self
    end

    def bnode?
      id.is_a?(BNodeID)
    end    
  end
end

def Node id, graph=nil
  graph.nil? ? RDF::Node.new(id, graph) : graph[id]
end
