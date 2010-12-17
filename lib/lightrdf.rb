$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module RDF
  VERSION = '0.1.5'
end

require 'rubygems'
require 'active_support'
require 'uri'
require 'open3'
require 'open-uri'
require 'tmpdir'
require 'rest-client'
require 'yaml'
require 'monitor'

require "lightrdf/quri"
require "lightrdf/parser"
require "lightrdf/graph"
require "lightrdf/node"
require "lightrdf/repository"
