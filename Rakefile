require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/lightrdf'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'lightrdf' do
  self.developer 'José Ignacio', 'joseignacio.fernandez@gmail.com'
  self.summary = "Light and easy library for managing RDF data and graphs"
  self.post_install_message = '**Remember to install raptor RDF tools and (optionally for RDF PNG output) Graphviz**'
  self.rubyforge_name       = self.name # TODO this is default value
  self.extra_deps         = [['activesupport','>= 2.0.2']]
end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }
