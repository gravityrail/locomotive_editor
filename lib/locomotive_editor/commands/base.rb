require 'active_support/inflector'
require 'active_support/core_ext/string'

module LocomotiveEditor

  module Commands

    class Base

      def initialize(options)
        @options = options
        @name = @options[:name]
      end

      def run!
        raise 'Implementation of run! is missing'
      end

      def set_site
        @site_name = @options[:name]

        raise 'Can not generate a content type without a site name' if @site_name.nil?

        @folder = @site_name.parameterize('_')

        raise 'The site does not exist' unless File.directory?(@folder)

        LocomotiveEditor.site = @folder
      end

      def self.help_message
        ''
      end

      protected

      def yaml(hash_or_array)
        method = hash_or_array.respond_to?(:ya2yaml) ? :ya2yaml : :to_yaml
        string = (if hash_or_array.respond_to?(:keys)
          hash_or_array.dup.stringify_keys!
        else
          hash_or_array
        end).send(method)
        string.gsub('!ruby/symbol ', ':').sub('---', '').split("\n").map(&:rstrip).join("\n").strip
      end

    end

  end

end