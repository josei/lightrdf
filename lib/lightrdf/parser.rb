module RDF
  module Parser
    def to_ntriples; serialize :ntriples; end

    def serialize format, header=true
      nodes = if self.is_a?(Graph)
        nodes_as_objects = find([], [], nil).select{|n| n.is_a?(Node)}
        values - nodes_as_objects + nodes_as_objects # Put them at the end
      else [self]
      end

      case format.to_sym
      when :ntriples
        triples.map { |s,p,o| "#{serialize_chunk_ntriples(s)} #{serialize_chunk_ntriples(p)} #{serialize_chunk_ntriples(o)} ." } * "\n"
      when :yarf
        ns = respond_to?(:ns) ? QURI.ns.merge(self.ns) : QURI.ns
        if header
          (ns.map{|k,v| "#{k}: #{v}\n"} * '') + serialize_yarf(nodes, ns)
        else
          serialize_yarf(nodes, ns)
        end
      when :ejson
        stdin, stdout, stderr = Open3.popen3("python -mjson.tool")
        stdin.puts ActiveSupport::JSON.encode(serialize_ejson(nodes))
        stdin.close
        stdout.read
      when :png
        dot = serialize(:dot)
        ns = respond_to?(:ns) ? QURI.ns.merge(self.ns) : QURI.ns
        ns.each { |k,v| dot.gsub!(v, "#{k}:") }
        dot.gsub!(/label=\"\\n\\nModel:.*\)\";/, '')
        stdin, stdout, stderr = Open3.popen3("dot -o/dev/stdout -Tpng")
        stdin.puts dot
        stdin.close
        stdout.read
      when :rdf
        serialize(:rdfxml)
      else
        tmpfile = File.join(Dir.tmpdir, "rapper#{$$}#{Thread.current.object_id}")
        File.open(tmpfile, 'w') { |f| f.write(serialize(:ntriples)) }
        %x[rapper -q -i ntriples -o #{format} #{tmpfile}]
      end
    end

    def self.parse format, text
      case format
      when :ntriples
        graph = RDF::Graph.new
        graph.triples = text.split("\n").select{|l| l.strip!=''}.map do |l|
          s, p, o = l.strip.match(/\A(<\S+>|".*"|_:\w+)\s+(<\S+>|".*"|_:\w+)\s+(<\S+>|".*"|_:\w+)\s+\.\Z/).captures
          [parse_chunk_ntriples(s), parse_chunk_ntriples(p), parse_chunk_ntriples(o)]
        end
        graph
      when :yarf
        graph = RDF::Graph.new
        ns = {}
        # Preprocessing - Extract namespaces, remove comments, get indent levels
        lines = []
        text.split("\n").each_with_index do |line, n|
          if line =~ /(\A\s*#|\A\w*\Z)/ # Comment or blank line - do nothing
          elsif line =~ /\A(\w+):\s+(.+)/ # Namespace
            ns[$1.to_sym] = $2
          else # Normal line - store line number, get indent level and strip line
            lines << [n+1, (line.size - line.lstrip.size)/2,  line.strip]
          end
        end
        parse_yarf_nodes lines, graph, ns
        graph.ns = ns
        graph
      when :rdf
        parse :rdfxml, text
      when :ejson
        raise Exception, "eJSON format cannot be parsed (yet)"
      else
        begin
          stdin, stdout, stderr = Open3.popen3("rapper -q -i #{format} -o ntriples /dev/stdin")
          stdin.puts text
          stdin.close
        rescue
        end
        parse :ntriples, stdout.read
      end
    end

    private
    def self.parse_yarf_nodes lines, graph, ns, base_level=0, i=0
      nodes = []
      while i < lines.size
        number, level, line = lines[i]
        if level == base_level
          nodes << if line =~ /\A(".*")\Z/ # Literal
            i += 1
            ActiveSupport::JSON.decode($1)
          elsif line =~ /\A(.+):\Z/ # Node with relations
            node = Node(ID($1, ns), graph)
            i, relations = parse_yarf_relations(lines, graph, ns, level+1, i+1)
            relations.each { |predicate, object| node[predicate] = node[predicate] + [object] }
            node
          elsif line =~ /\A(.+)\Z/ # Node
            i += 1
            Node(ID($1, ns), graph)
          else
            raise Exception, "Syntax error on line #{number}"
          end
        elsif level < base_level
          break
        else
          raise Exception, "Indentation error on line #{number}"
        end
      end
      [i, nodes]
    end
    def self.parse_yarf_relations lines, graph, ns, base_level, i
      relations = []
      while i < lines.size
        number, level, line = lines[i]
        if level == base_level
          relations += if line =~ /\A(.+):\s+(".+")\Z/ # Predicate and literal
            i += 1
            [[Node(ID($1, ns), graph), ActiveSupport::JSON.decode($2)]]
          elsif line =~ /\A(.+):\s+(.+)\Z/ # Predicate and node
            i += 1
            [[Node(ID($1, ns), graph), Node(ID($2, ns), graph)]]
          elsif line =~ /\A(.+):\Z/ # Just the predicate
            predicate = Node(ID($1, ns), graph)
            i, objects = parse_yarf_nodes(lines, graph, ns, level+1, i+1)
            objects.map {|n| [predicate, n]}
          end
        elsif level < base_level
          break
        else
          raise Exception, "Indentation error on line #{number}"
        end
      end
      [i, relations]
    end

    def serialize_yarf nodes, ns=QURI.ns, level=0, already_serialized=[]
      text = ""

      for node in nodes
        next if level == 0 and (node.triples.size == 0 or already_serialized.include?(node))
        text += " " *level*2 
        text += serialize_chunk_yarf(node, ns)
        if already_serialized.include?(node) or !node.is_a?(Node) or node.triples.size == 0
          text += "\n"
        else
          already_serialized << node
          text += ":\n"
          node.predicates.each do |p, o| # Predicate and object
            text += " " *(level+1)*2
            text += p.id.compressed(ns)
            text += ":"
            if o.size == 1 and (already_serialized.include?(o.first) or !o.first.is_a?(Node) or o.first.triples.size==0)
              text += " " + serialize_chunk_yarf(o.first, ns)
              text += "\n"
            else
              text += "\n" + serialize_yarf(o, ns, level+2, already_serialized)
            end
          end
        end
      end
      text
    end
    
    def serialize_chunk_yarf node, ns=QURI.ns
      if node.is_a?(Node)
        if node.bnode?
          if node.graph.find(nil, [], node).size > 1 # Only use a bnode-id if it appears again as object
            node.id.to_s
          else
            "*"
          end
        else
          node.id.compressed ns
        end
      else
        ActiveSupport::JSON.encode(node)
      end
    end

    def serialize_ejson nodes, already_serialized=[], level=0
      list = []

      nodes.each do |n|
        if n.is_a?(Node)
          if already_serialized.include?(n)
            list << { 'id' => n.to_s } unless level == 0
          else
            already_serialized << n
            hash = { 'id' => n.to_s }
            n.predicates.each do |k,v|
              hash[k.to_s] = serialize_ejson(v, already_serialized, level+1)
            end
            list << hash
          end
        else
          list << n.to_s
        end
      end

      list
    end

    def serialize_chunk_ntriples n
      if n.is_a? Node 
        n.bnode? ? n.to_s : "<#{n}>"
      else
        ActiveSupport::JSON.encode(n)
      end
    end
  
    def self.parse_chunk_ntriples c
      case c[0..0]
      when '<' then Node c[1..-2]
      when '_' then Node c
      when '"' then
        ActiveSupport::JSON.decode(c)
      else
        raise Exception, "Parsing error: #{c}"
      end
    end
  end
end
