require 'rubygems'
require 'rake'
require 'echoe'
require './lib/lightrdf'

Echoe.new('lightrdf', RDF::VERSION) do |p|
  p.description    = "RDF library"
  p.summary        = "Light and easy library for managing RDF data and graphs"
  p.url            = "http://github.com/josei/lighrdf"
  p.author         = "Jose Ignacio"
  p.email          = "joseignacio.fernandez@gmail.com"
  p.install_message = '**Remember to install raptor RDF tools and (optionally for RDF PNG output) Graphviz**'
  p.ignore_pattern = ["pkg/*"]
  p.dependencies   = [['activesupport','>= 2.0.2'], ['rest-client', '>=1.6.1'], ['nokogiri', '>= 1.4.1']]
end

Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_files.include('README.rdoc').include('lib/**/*.rb')
  rdoc.main = "README.rdoc"
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each
