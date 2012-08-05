require 'erb'
require 'ostruct'

module LocomotiveEditor

  module SiteTemplates

    class Template

      attr_accessor :name, :target_folder, :options

      def initialize(name, folder, options)
        self.name, self.target_folder, self.options = name, folder, options
      end

      def create!
        self.prepare_target_folder

        self.copy_files

        self.create_config_files

        self.assign_version
      end

      def name
        self.class.name.demodulize.underscore
      end

      def source_folder
        raise "the source_folder method is missing for the template #{self.name}"
      end

      protected

      def prepare_target_folder
        puts "\t...preparing target folder (#{LocomotiveEditor.site_root})"
        FileUtils.mkdir_p LocomotiveEditor.site_root
      end

      def copy_files
        puts %(\t...copy files from the template "#{self.name}")
        FileUtils.cp_r File.join(self.source_folder, '.'), File.join(LocomotiveEditor.site_root, '/')
      end

      def create_config_files
        puts "\t...generate config/site.yml file"
        content = File.open(File.join(self.source_folder, 'config', 'site.yml')).read
        content = ERB.new(content).result(OpenStruct.new(:name => self.name).send(:binding))
        File.open(File.join(LocomotiveEditor.site_root, 'config', 'site.yml'), 'w') do |f|
          f.write(content)
        end

        puts "\t...generate config/deploy.yml file"
        File.open(File.join(LocomotiveEditor.site_root, 'config', 'deploy.yml'), 'w') do |f|
          f.write <<-YAML
development:
  host: dev.example.com
  email: john@doe.net
  password: easyone
staging:
  host: staging.example.com
  email: john@doe.net
  password: easyone
production:
  host: www.example.com
  email: john@doe.net
  password: easyone
          YAML
        end

        puts "\t...generate config/compass.rb file"
        tmp_dir = File.join(LocomotiveEditor.site_root, 'tmp')
        FileUtils.mkdir_p tmp_dir
        File.open(File.join(LocomotiveEditor.site_root, 'config', 'compass.rb'), 'w') do |f|
          f.write <<-TEXT
# Please, be careful when editing these settings, it may break the theme assets API push
project_path      = File.join(File.dirname(__FILE__), '..', 'public')
http_path         = '/'
css_dir           = '../tmp/stylesheets'
sass_dir          = 'stylesheets'
images_dir        = 'images'
javascripts_dir   = 'javascripts'
project_type      = :stand_alone
output_style      = :nested
line_comments     = false
          TEXT
        end
      end

      def assign_version
        puts "\t...initialize first version"
        File.open(File.join(LocomotiveEditor.site_root, 'VERSION'), 'w') do |f|
          f.write('0.0.1')
        end
      end

    end

  end

end