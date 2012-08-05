require 'active_support/core_ext/hash/indifferent_access'

module LocomotiveEditor

  module Commands

    class Run < Base

      def initialize(options)
        @options = options

        LocomotiveEditor.check_if_sites_exist_and_select!(@options[:name])

        LocomotiveEditor.settings[:hide_sites_selector] = @options[:name].present?

        @gem_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))

        # config defaults
        @config = {
          :environment          => 'development',
          :chdir                => '.',
          :address              => '0.0.0.0',
          :port                 => '4567',
          :rackup               => File.join(@gem_root, 'config.ru'),
          :pid                  => 'tmp/pids/thin.pid', #'./tmp/pids/thin.pid',
          :log                  => 'logs/thin.log', #'./logs/thin.log'
          :max_conns            => 1024,
          :timeout              => 30,
          :max_persistent_conns => 512,
          :daemonize            => false
        }
      end

      def run!
        self.find_local_config

        require 'thin'

        thin = Thin::Runner.new([])
        thin.command = 'start'

        thin.options.merge!(@config)
        thin.run!
      end

      def self.help_message
        """
Some examples:

* Launch the webserver

  > locomotive_editor run

  Note:
    - if you run the command at the root of a list of site folders, then a little select box will be displayed at the top right corner
      in your browser in order to switch from a website to another one.

* Launch the webserver for a specific website

  > locomotive_editor run -n awesome_website"""
      end

      protected

      def find_local_config
        if File.exists?('config.yml')
          puts "...using local config.yml file"
          config_yaml = File.read('config.yml')
          @config.merge!(YAML::load(config_yaml).symbolize_keys)
        end
      end

    end

  end
end