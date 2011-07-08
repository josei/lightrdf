require File.dirname(__FILE__) + '/test_helper.rb'

Namespace :ex,   'http://www.example.com/ontology#'
Namespace :foaf, 'http://xmlns.com/foaf/0.1/'

module Foaf
  class Person
    include RDF::NodeProxy

    # Adds 1 year to the person's age
    def happy_birthday!
      foaf::age = (foaf::age.first.to_i + 1).to_s
    end
  end
end

module Foaf
  class Thing
    include RDF::NodeProxy
    maps 'http://xmlns.com/foaf/0.1/Agent'
  end
end

class TestLightRDF < Test::Unit::TestCase
  def test_equality
   assert Node('_:something') == Node(Node('_:something'))
   assert ID('_:2') == ID('_:2')
   assert ID('http://www.w3.org/1999/02/22-rdf-syntax-ns#type') == ID('rdf:type')
   assert Node('_:2') == Node('_:2')
  end

  def test_ids
    assert ID('rdf:type') == :'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
    assert ID('_:bnode') == :'_:bnode'
    assert ID('http://www.google.com') == :'http://www.google.com'
  end

  def test_type
    assert RDF::ID.uri?(ID('rdf:type'))
    assert RDF::ID.uri?(ID('http://www.google.com'))
    assert RDF::ID.bnode?(ID('*'))
    assert RDF::ID.bnode?(ID('_:bnode'))
  end
  
  def test_random_node
    assert Node(nil).is_a?(RDF::Node)
  end

  def test_graph
    graph = RDF::Graph.new
    assert_equal graph['rdf:type'], graph[Node('rdf:type')]
    assert_equal graph['rdf:type'], graph['rdf:type']
    assert_not_equal graph['foaf:name'], graph[Node('foaf::nick')]
    assert_not_equal graph['rdf:type'], graph[Node('rdf:class')]
    assert !graph['rdf:type'].eql?(graph[Node('rdf:class')])
  end

  def test_namespaces
    assert_equal Node('http://www.example.com/ontology#test'), Node('ex:test')
  end

  def test_attributes
    a = Node('ex:bob')
    a.foaf::name = "Bob"
    assert_equal "Bob", a.foaf::name.first
  end

  def test_query
    a = Node('ex:bob')
    a.foaf::name = "Bob"
    a.foaf::age = "24"

    b = Node('ex:alice')
    b.foaf::name = "Alice"
    b.foaf::age = "22"

    g = RDF::Graph.new
    g << a
    g << b

    assert_equal [Node('ex:alice')], g.find(nil, Node('foaf:age'), "22")
    assert_equal [Node('foaf:age'), Node('foaf:name')], g.find(Node('ex:bob'), nil, []).sort_by {|node| node.to_s}
  end

  def test_addition
    a = Node('ex:bob')
    a.foaf::weblog = Node('http://www.awesomeweblogfordummies.com')
    a.foaf::weblog += [Node('http://www.anotherawesomeweblogfordummies.com')]
    assert_equal 2, a.foaf::weblog.size
    assert a.foaf::weblog?(Node('http://www.awesomeweblogfordummies.com'))
  end

  def test_triples
    a = Node('ex:bob')
    a.foaf::weblog = Node('http://www.awesomeweblogfordummies.com')
    g = RDF::Graph.new a.triples
    assert g[Node('ex:bob')].foaf::weblog?(Node('http://www.awesomeweblogfordummies.com'))
    assert_equal 1, [g[Node('ex:bob')].graph.object_id, g[Node('ex:bob')].foaf::weblog.map(&:graph).map(&:object_id)].flatten.uniq.size
  end

  def test_rename
    a = Node('ex:alice')
    a.foaf::name = "Alice"
    b = Node('ex:bob')
    b.foaf::knows = a
    a.graph << b
    a.foaf::knows = b
    
    c = a.rename 'ex:ana'

    assert a.graph['ex:alice'].foaf::knows.include?(Node('ex:bob'))
    assert a.foaf::knows.first.foaf::knows.include?(Node('ex:alice'))

    assert c.graph['ex:ana'].foaf::knows.include?(Node('ex:bob'))
    assert c.foaf::knows.first.foaf::knows.include?(Node('ex:ana'))
  end
  
  def test_rename!
    a = Node('ex:alice')
    a.foaf::name = "Alice"
    b = Node('ex:bob')
    b.foaf::knows = a
    a.graph << b
    a.foaf::knows = b
    
    a.rename! 'ex:ana'

    assert a.graph['ex:ana'].foaf::knows.include?(Node('ex:bob'))
    assert a.foaf::knows.first.foaf::knows.include?(Node('ex:ana'))
  end

  def test_node_merge
    a = Node('ex:alice')
    a.foaf::name = "Alice"
    b = Node('ex:alice')
    b.foaf::age = "23"

    c = a.merge(b)

    assert_not_same ["Alice"], b.foaf::name
    assert_not_same ["23"], a.foaf::age
    assert_equal ["Alice"], c.foaf::name
    assert_equal ["23"], c.foaf::age
  end

  def test_node_merge!
    a = Node('ex:alice')
    a.foaf::name = "Alice"
    b = Node('ex:alice')
    b.foaf::age = "23"

    a.merge!(b)

    assert_equal ["Alice"], a.foaf::name
    assert_equal ["23"], a.foaf::age
  end

  def test_recursive_add
    a = Node('ex:alice')
    a.foaf::name = "Alice"
    b = Node("ex:bob", a.graph)
    b.foaf::age = "26"
    a.foaf::knows = b

    g = RDF::Graph.new
    g << a

    assert_equal ["Alice"], g[Node("ex:alice")].foaf::name
    assert_equal [Node("ex:bob")], g[Node("ex:alice")].foaf::knows
    assert_equal ["26"], g[Node("ex:bob")].foaf::age
  end

  def test_all_triples
    a = Node('ex:alice')
    a.foaf::name = "Alice"
    b = Node("ex:bob")
    b.foaf::age = "26"
    a.foaf::knows = b
    c = Node("ex:charlie")
    c.foaf::age = "27"

    g = RDF::Graph.new
    g << a
    g << b
    g << c

    g.triples -= a.all_triples
    
    assert_equal 1, g.triples.size
    assert_equal ["27"], g[Node("ex:charlie")].foaf::age
  end

  def test_graph_merge!
    a = Node('ex:bob')
    a.foaf::name = "Bob"

    b = Node('ex:alice')
    b.foaf::name = "Alice"

    g1 = RDF::Graph.new
    g2 = RDF::Graph.new
    g1 << a
    g2 << b

    g2.merge!(g1)

    assert_equal ["Alice"], g2[Node('ex:alice')].foaf::name
    assert_equal ["Bob"], g2[Node('ex:bob')].foaf::name
    assert_equal 2, g2.triples.size
  end

  def test_graph_merge
    a = Node('ex:bob')
    a.foaf::name = "Bob"

    b = Node('ex:alice')
    b.foaf::name = "Alice"

    g1 = RDF::Graph.new
    g2 = RDF::Graph.new
    g1 << a
    g2 << b

    g3 = g1.merge(g2)

    assert_equal ["Alice"], g3[Node('ex:alice')].foaf::name
    assert_equal ["Bob"], g3[Node('ex:bob')].foaf::name
    assert_equal g1, a.graph
    assert_equal g2, b.graph
    assert_equal 2, g3.triples.size
  end

  def test_parsing
    text = """
dc: http://purl.org/dc/elements/1.1/
rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns#
ex: http://www.example.com/ontology#
foaf: http://xmlns.com/foaf/0.1/
*:
  rdf:type: rdf:Resource
  foaf:name: \"Bob\"
  foaf:weblog:
    \"http://www.awesomeweblogfordummies.com\"
    http://www.anotherawesomeweblogfordummies.com:
      dc:title: \"Another awesome blog\"
"""

    assert_equal 5, RDF::Parser.parse(:yarf, text).triples.size
  end

  def test_parsing_raptor
    assert RDF::Parser.parse(:rdf, open('http://planetrdf.com/guide/rss.rdf').read).serialize(:ntriples).split("\n").size > 10
  end

  def test_serialization
    a = Node('ex:bob')
    a.foaf::name = "Bob"
    a.foaf::age = "23"

    g = RDF::Graph.new
    g << a

    assert 2, g.to_ntriples.split("\n").size
  end

  def test_serialization_raptor
    a = Node('ex:bob')
    a.foaf::name   = "Bob"
    a.foaf::age    = "23"
    a.ex::location = Node(nil)

    g = RDF::Graph.new
    g << a

    g.serialize(:ejson) # Just check that parsing doesn't crash
    assert_equal 3, RDF::Parser.parse(:yarf,   g.serialize(:yarf)  ).triples.size
    assert_equal 3, RDF::Parser.parse(:rdfxml, g.serialize(:rdfxml)).triples.size
    assert_equal 3, RDF::Parser.parse(:rdf,    g.serialize(:rdf)   ).triples.size
  end
  
  def test_repository
    repository = RDF::Repository.new
    triple = [ID("http://testuri.org"), ID('rdf:type'), ID('rdf:Class')]
    graph = RDF::Graph.new [triple]
    context = "http://test_context.org"
    repository.data = graph, context
    
    # Check if the added data is there
    assert_equal graph, repository.data(context)
    assert_equal graph, repository.data(context, context)
    assert_equal graph, repository.data([context, context])
    
    # Check if the triple is there when not filtering by context
    assert repository.data.triples.include?(triple)
  end
  
  def test_repository_contexts
    repository = RDF::Repository.new
    graph = RDF::Graph.new [[Node("http://testuri.org"), Node('rdf:type'), Node('rdf:Class')]]
    context = "http://test_repository_contexts.org"
    repository.data = graph, context
    contexts = repository.contexts

    # Check if the added context is there
    assert contexts.include?("http://test_repository_contexts.org")
  end

  def test_repository_sparql
    repository = RDF::Repository.new
    graph = RDF::Graph.new [[Node("http://testuri.org"), Node('rdf:type'), Node('rdf:Class')]]
    repository.data = graph
    results = repository.query("?q rdf:type rdf:Class")

    assert_equal [Node("http://testuri.org")], results.uniq
  end

  def test_instantiation
    assert_equal Node("foaf:Person"), Foaf::Person.new.rdf::type.first
    assert_equal Node("foaf:Agent"),  Foaf::Thing.new.rdf::type.first

    person_node = Node(nil)
    person_node.foaf::age = "19"
    person = Foaf::Person.new(person_node)
    assert_equal ["19"], person.foaf::age 
  
    person = Foaf::Person.new('foaf:age'=>"25", 'rdf:type'=>Node('rdf:Resource'))
    person.happy_birthday!
    assert_equal ["26"], person.foaf::age
    assert_equal Node("foaf:Person"), person.rdf::type.first
  end

  def test_graph_instantiation
    graph       = RDF::Graph.new
    person_node = Node(nil)
    person_node.rdf::type = Node('foaf:Person')
    person_node.foaf::age = "25"
    graph << person_node

    person = graph.node(person_node)
    person.happy_birthday!
    assert_equal ["26"], person.foaf::age
    assert_equal person.object_id, graph.node(person_node).object_id
  end

  def test_instance_equality
    node   = Node(nil)
    node.foaf::age = "25"
    person1 = Foaf::Person.new(node)
    person2 = Foaf::Person.new(node)
    assert_equal person1.id, person2.id
  end
  
  def test_graph_contains
    graph1 = RDF::Graph.new [ [Node('ex:alice'), Node('foaf:age'), "24"]]
    graph2 = RDF::Graph.new [ [Node('ex:alice'), Node('foaf:knows'), Node('_:bnode392')],
                              [Node('_:bnode392'), Node('foaf:name'), "Bob"] ]
    graph3 = RDF::Graph.new [ [Node('ex:alice'), Node('foaf:knows'), Node('_:bnode965')],
                              [Node('_:bnode965'), Node('foaf:name'), "Bob"] ]
    graph4 = RDF::Graph.new [ [Node('ex:alice'), Node('foaf:knows'), Node('_:bnode392')],
                              [Node('_:bnode392'), Node('foaf:name'), "Robert"] ]
    graph5 = RDF::Graph.new [ [Node('ex:alice'), Node('foaf:knows'), Node('_:bnode390')],
                              [Node('_:bnode390'), Node('foaf:name'), "Robert"],
                              [Node('ex:alice'), Node('foaf:knows'), Node('_:bnode967')],
                              [Node('_:bnode967'), Node('foaf:name'), "Bob"]]
    assert !graph1.contains?(graph2)
    assert graph2.contains?(graph3)
    assert !graph2.contains?(graph4)
    assert graph2 != graph4
    assert graph5.contains?(graph2)
  end
end
