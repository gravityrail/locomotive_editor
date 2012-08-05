module LocomotiveEditor

  module Commands

    class List < Base

      def initialize(options)
        @options = options
      end

      def run!
        list = LocomotiveEditor.sites

        if list.empty?
          puts 'No sites found'
        else
          puts "#{list.size} site(s) found:"
          list.each do |site|
            puts "\t- #{site.name} (#{site.folder})"
          end
        end
      end

      def self.help_message
        """
Some examples:

* List of the available sites in a root folder

  > locomotive_editor list"""
      end

    end

  end

end