$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module RDF
  VERSION = '0.2.6'
end

require 'rubygems'
require 'active_support'
require 'uri'
require 'open-uri'
require 'tmpdir'
require 'rest-client'
require 'yaml'
require 'monitor'
require 'nokogiri'

require "lightrdf/id"
require "lightrdf/parser"
require "lightrdf/graph"
require "lightrdf/node"
require "lightrdf/node_proxy"
require "lightrdf/repository"
