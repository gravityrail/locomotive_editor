require 'sass/plugin'
require 'compass'

module LocomotiveEditor

  module Compass

    def self.compile!
      ::Compass.add_project_configuration("#{LocomotiveEditor.site_root}/config/compass.rb")
      args      = ::Compass.configuration.to_compiler_arguments(:logger => ::Compass::NullLogger.new)
      compiler  = ::Compass::Compiler.new *args
      compiler.run
    end

  end

end