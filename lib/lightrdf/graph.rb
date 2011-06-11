module RDF
  class Graph < Hash
    include Parser
    alias :get :[]
    
    # Namespace set stored when parsing a file. Can be used for reference
    attr_accessor :ns
    
    # Set of initialized RDF::NodeProxy objects
    attr_accessor :pool
    
    def initialize triples=[]
      super(nil)
      @ns   = {}
      @pool = {}
      self.triples = triples
    end

    def << node
      node.graph.each do |subid, subnode|
        subnode.graph = self
        old_subnode = get(subid)
        self[subid] = old_subnode ? old_subnode.merge!(subnode) : subnode
      end
      old_node = get(node.id)
      self[node.id] = old_node ? old_node.merge!(node) : node
    end

    def [] id
      super(ID(id)) || Node.new(id, self)
    end
    def nodes; values; end
    def inspect
      "{" + (values.map{|v| v.inspect} * ", ") + "}"
    end
    def merge! graph
      graph.values.each { |node| self << node }
      self
    end
    def merge graph
      RDF::Graph.new(triples + graph.triples)
    end
    def triples
      triples = []; values.each { |n| triples += n.triples }
      triples
    end
    def triples= triples
      self.clear
      triples.each { |s, p, o| self[s][p] += [o.is_a?(Symbol) ? self[o] : o] }
    end
    def select &block
      values.select &block
    end
    
    # Returns true if the graph is contained into this one.
    # It appropriately disambiguates blank nodes.
    def contains? graph2
      triples  = self.triples
      triples2 = graph2.triples
      return false if triples2.size > triples.size
      
      bnodes  = self.keys.select   { |node| ID::bnode?(node) }
      bnodes2 = graph2.keys.select { |node| ID::bnode?(node) }

      # Tries all the mappings between blank nodes
      mappings = bnodes2.mappings(bnodes)

      mappings.each do |mapping|
        new_triples = triples2.map { |s,p,o| [ ID::bnode?(s) ? mapping[s] : s,
                                               ID::bnode?(p) ? mapping[p] : p,
                                               ID::bnode?(o) ? mapping[o] : o ]}
        diff = triples - new_triples
        return true if diff.size == triples.size - new_triples.size
      end
      
      false
    end
    
    def == graph2
      triples.size == graph2.triples.size and contains?(graph2)
    end
    
    # This is equivalent to [], but tries to return a NodeProxy
    # It stores created objects in a pool
    def node id, type=nil
      id = ID(id)
      @pool[id] ||= begin
        node   = self[id]
        type ||= node.rdf::type.first
        klass  = Node.classes[type]
        raise Exception, "Unknown RDF-mapped type #{type}" unless klass
        klass.new(node)
      end
    end
    
    def clone
      graph = self.class.new
      each do |id, node|
        new_node = graph[id]
        node.each do |predicate, objects|
          new_node[predicate] = objects.map { |object| object.is_a?(Node) ? graph[object] : object }
        end
      end
      graph
    end
    
    def delete value
      value.is_a?(Symbol) ? super : super(value.id)
    end
    
    def find subject, predicate, object
      # Convert nodes into IDs
      subject   = subject.id   if subject.is_a?(Node)
      predicate = predicate.id if predicate.is_a?(Node)
      object    = object.id    if object.is_a?(Node)

      # Find nodes
      matches = triples.select { |s,p,o| (subject.nil?   or subject  ==[] or s==subject)   and
                                         (predicate.nil? or predicate==[] or p==predicate) and
                                         (object.nil?    or object   ==[] or o==object) }

      # Build results
      result = []
      result += matches.map {|t| t[0] } if subject.nil?
      result += matches.map {|t| t[1] } if predicate.nil?
      result += matches.map {|t| t[2] } if object.nil?
      
      # Return nodes, not IDs
      result.uniq.map { |id| id.is_a?(Symbol) ? Node(id, self) : id }
    end
  end
end
