require 'singleton'

module LocomotiveEditor

  module SiteTemplates

    class Manager

      include ::Singleton

      attr_accessor :list

      def initialize
        self.list = {}
      end

      def register(name, klass)
        self.list[name.to_sym] = klass
      end

      def self.register(name, klass)
        self.instance.register(name, klass)
      end

      def self.list
        self.instance.list
      end

      def self.get(name)
        self.instance.list[name.to_sym]
      end

    end

  end

end