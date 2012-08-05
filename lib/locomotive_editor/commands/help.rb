module LocomotiveEditor

  module Commands

    class Help < Base

      def initialize(options, command_line_options)
        command_name = command_line_options.first

        raise "You have to pass a command name as the second argument" if command_name.blank?

        begin
          @klass = "LocomotiveEditor::Commands::#{command_name.capitalize}".constantize
        rescue
          raise "The \"#{command_name}\" command does not exist"
        end
      end

      def run!
        puts @klass.help_message
      end

      def self.help_message
        "Inception mode enabled"
      end

    end

  end

end