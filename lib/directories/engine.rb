require 'rubygems'
require 'less-rails'
require 'less/rails/bootstrap'
require 'bh'
require 'cancancan'
require 'lodash-rails'

module Directories
  class Engine < ::Rails::Engine
    isolate_namespace Directories
    Dir[File.join(root, "lib", "core_ext", "*.rb")].each { |l| require l }
  end
end
