module LocomotiveEditor

  module SiteTemplates

    class Empty < Template

      def self.message
        %(this is the default template, very minimal)
      end

      def source_folder
        File.join(File.dirname(File.expand_path(__FILE__)), 'empty', '/')
      end

    end

    LocomotiveEditor::SiteTemplates::Manager.register(:empty, Empty)

  end

end

