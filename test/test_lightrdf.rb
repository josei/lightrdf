require File.dirname(__FILE__) + '/test_helper.rb'

class TestLightRDF < Test::Unit::TestCase

  def setup
    Namespace :ex,   'http://www.example.com/ontology#'
    Namespace :foaf, 'http://xmlns.com/foaf/0.1/'
    Namespace :sc,   'http://lab.gsi.dit.upm.es/scrapping.rdf#'
  end
  
  def test_equality
   assert Node('_:something') == Node(Node('_:something'))
   assert ID('_:2') == ID('_:2')
   assert ID('http://www.w3.org/1999/02/22-rdf-syntax-ns#type') == ID('rdf:type')
   assert Node('_:2') == Node('_:2')
  end

  def test_type
    assert ID('rdf:type').is_a?(RDF::ID)
    assert ID('_:bnode').is_a?(RDF::ID)
    assert ID('http://www.google.com').is_a?(RDF::ID)
    assert URI.parse('http://www.google.com').is_a?(RDF::ID)
    assert ID('*').is_a?(RDF::ID)
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

    assert_equal 1, g.find(nil, Node('foaf:age'), "22").size
    assert_equal 2, g.find(Node('ex:bob'), nil, []).size
  end

  def test_addition
    a = Node('ex:bob')
    a.foaf::weblog = Node('http://www.awesomeweblogfordummies.com')
    a.foaf::weblog << Node('http://www.anotherawesomeweblogfordummies.com')
    assert_equal 2, a.foaf::weblog.size
    assert a.foaf::weblog?(Node('http://www.awesomeweblogfordummies.com'))
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

    assert ["Alice"], g3[Node('ex:Alice')].foaf::name
    assert ["Bob"], g3[Node('ex:bob')].foaf::name
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
    # Very naive testing -- it only helps to check that rapper is being executed
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

  def test_repository
    repository = RDF::Repository.new
    graph = RDF::Graph.new([[Node("http://testuri.org"), Node('sc:extraction'), Node('sc:Empty')]])
    context = "testcontext:#{Time.now.day.to_s}#{Time.now.hour.to_s}#{Time.now.min.to_s}"
    repository.post_data(graph, context)
    ext = repository.get_data(["%3C#{context}%3E"])
    assert graph, ext
  end
end
