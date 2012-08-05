require 'rubygems'
gemfile = File.join(File.dirname(__FILE__), '../Gemfile')

if File.exist?(gemfile)
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'

  # we do not want to load specs for the gems from the development, test groups
  require 'bundler/definition'
  module Bundler
    class Definition

      if ::Bundler::VERSION < '1.2'
        def initialize_with_path(lockfile, dependencies, sources, unlock)
          dependencies.reject!{ |d| (d.groups - Bundler.settings.without).empty? }
          initialize_without_path(lockfile, dependencies, sources, unlock)
        end
      else
        def initialize_with_path(lockfile, dependencies, sources, unlock, ruby_version = "")
          dependencies.reject!{ |d| (d.groups - Bundler.settings.without).empty? }
          initialize_without_path(lockfile, dependencies, sources, unlock, ruby_version)
        end
      end

      alias_method :initialize_without_path, :initialize
      alias_method :initialize, :initialize_with_path
    end
  end

  Bundler.settings.without = [:test, :development]

  Bundler.require
end
