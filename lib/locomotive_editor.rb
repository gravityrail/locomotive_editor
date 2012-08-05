require 'ostruct'
require 'yaml'
require 'sinatra'
require 'sass'
require 'compass'
require 'liquid'
require 'httmultiparty'
require 'will_paginate'
require 'active_support/inflector'
require 'active_support/core_ext/object'

if Gem.loaded_specs['activesupport'].version > Gem::Version.create('3.2.0.pre') # ActiveSupport 3.2
  require 'active_support/core_ext/class/attribute'
else # ActiveSupport 3.0, 3.1
  require 'active_support/core_ext/class/inheritable_attributes'
end

require 'active_support/core_ext/string'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/module/aliasing'
require 'active_support/core_ext/hash/indifferent_access'
require 'sinatra/i18n'
require 'locomotive_editor/logger'

module LocomotiveEditor

  def self.settings
    @@settings ||= {}
    @@settings
  end

  def self.site_root
    self.settings['site_root']
  end

  def self.site_templates_root
    return nil if site_root.blank?
    File.join(site_root, 'app', 'views', 'pages')
  end

  def self.site_snippets_root
    File.join(site_root, 'app', 'views', 'snippets')
  end

  def self.site=(site)
    @current_site = site
    self.settings['site_root'] = File.expand_path(File.join('.', @current_site))
  end

  def self.current_site
    @current_site
  end

  def self.sites
    if File.exists?(File.join('config', 'site.yml'))
      [OpenStruct.new(:folder => '.', :name => self.site_config['site']['name'])]
    else
      Dir['./*'].collect do |folder|
        next unless File.directory?(folder)

        if File.exists?(File.join(folder, 'config', 'site.yml'))
          site_config = self.site_config(folder) rescue nil

          next if site_config.nil?

          OpenStruct.new(:folder => File.basename(folder), :name => site_config['site']['name'])
        end
      end.compact
    end
  end

  def self.site_config(folder = '.')
    config_yaml = File.read(File.join(folder, 'config', 'site.yml'))
    begin
      YAML::load(config_yaml)
    rescue Exception => e
      LocomotiveEditor::Logger.error "Unable to read the #{File.join(folder, 'config', 'site.yml')} file"
      raise
    end
  end

  def self.check_if_sites_exist_and_select!(name)
    sites = LocomotiveEditor.sites
    if sites.empty?
      raise "No site(s) found. You can create one with the create command."
    else
      site = sites.first

      unless name.nil?
        site = sites.detect { |s| File.basename(s.folder) == name || s.name == name }
      end

      if site.nil?
        raise "No site found matching the name '#{name}'"
      else
        LocomotiveEditor.site = site.folder
      end
    end
  end

  def self.require_ext_loader
    if LocomotiveEditor.settings[:loader_file]
      LocomotiveEditor::Logger.info "...loading external extensions (#{LocomotiveEditor.settings[:loader_file]})"
      require LocomotiveEditor.settings[:loader_file]
    end
  end

  def self.ext_files
    files = []
    if LocomotiveEditor.settings[:loader_file]
      files = [LocomotiveEditor.settings[:loader_file]]
      files += Dir[File.join(LocomotiveEditor.settings[:loader_path], '/**/*.rb')] if LocomotiveEditor.settings[:loader_path]
    end
    files
  end

  def self.reload_site
    LocomotiveEditor::Models::Base.reload!

    LocomotiveEditor::SinatraApp.set(:public_folder, File.join(LocomotiveEditor.site_root, 'public'))
    LocomotiveEditor::SinatraApp.set(:views, File.join(LocomotiveEditor.site_root, 'public'))

    LocomotiveEditor::SinatraApp.configure do
      ::Compass.add_project_configuration(File.join(LocomotiveEditor.site_root, 'config', 'compass.rb'))

      # set :haml, { :format => :html5 }
      set :scss, ::Compass.sass_engine_options
    end
  end

  def self.current_site
    LocomotiveEditor::Models::Site.first
  end

end