module RDF  
  # This class allows instantiating RDF resources as Ruby objects
  module NodeProxy
    def self.included base
      base.extend ClassMethods
      base.send :attr_reader, :node
      base.maps(base.to_s.gsub("::",":").gsub(/\A.*:/) { |a| a.downcase })
    end
    
    module ClassMethods
      def inherited subclass
        subclass.maps(subclass.to_s.gsub("::",":").gsub(/\A.*:/) { |a| a.downcase })
      end
      
      def maps id
        @rdf_type = Node(id)
        Node.classes.delete Node.classes.invert[self]
        Node.classes[@rdf_type] = self
      end
    end

    # Constructor that allows 
    def initialize arg=nil
      @node = if arg.is_a?(RDF::Node)
        arg
      elsif arg.is_a?(Hash)
        new_node = Node('*')
        new_node.rdf::type = rdf_type
        arg.each { |k,v| new_node[k] = (new_node[k] + [v].flatten).uniq }
        new_node
      else
        new_node = Node('*')
        new_node.rdf::type = rdf_type
        new_node
      end
    end
    
    # Equality method delegated to node
    def == other_node
      eql? other_node
    end
    # Equality method delegated to node
    def eql? other_node
      self.class == other_node.class and @node.id == other_node.node.id
    end
    # Hash method delegated to node
    def hash # Hack for Ruby 1.8.6
      @node.id.hash ^ self.class.hash
    end
    
    # to_s method delegated to node
    def to_s
      @node.to_s
    end
    
    # id method delegated to node
    def id
      @node.id
    end
    
    # clone method delegated to node
    def clone
      node.clone.proxy(rdf_type)
    end
    
    def rdf_type
      self.class.instance_variable_get("@rdf_type")
    end
    
    # Any other method (including any predicate) delegated to node
    def method_missing method, *args
      @node.send method, *args
    end
  end
end