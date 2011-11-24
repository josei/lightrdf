$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module RDF
  VERSION = '0.4.1'
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

class Array
  # Returns an array of hashes with the possible mappings
  # between the elements in both arrays
  def mappings array2
    return [{}] if self.empty? or array2.empty?
    mappings = []
    each do |item|
      mapping = {}
      array2.each do |item2|
        mapping[item] = item2
        (self - [item]).mappings(array2 - [item2]).each do |submapping|
          mappings << mapping.merge(submapping)
        end
      end
    end
    mappings.uniq
  end
end
