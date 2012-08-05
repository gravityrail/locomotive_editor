module LocomotiveEditor

  module Commands

    class ListTemplates < Base

      def initialize(options)
        @options = options

        LocomotiveEditor.require_ext_loader
      end

      def run!
        list = LocomotiveEditor::SiteTemplates::Manager.list

        if list.empty?
          puts 'No templates found. Well, something must have gone wrong.... Please contact us.'
        else
          puts "#{list.size} template(s) found:"
          list.each do |name, klass|
            puts "\t- #{name}: #{klass.message}"
          end
        end
      end

      def self.help_message
        """
Some examples:

* List of the available site templates available within the editor

  > locomotive_editor list_templates"""
      end

    end

  end

end