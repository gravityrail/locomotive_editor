module LocomotiveEditor

  module SiteTemplates

    class TwitterBootstrapHaml < Template

      def self.message
        %(includes all the files provided by the Twitter Bootstrap package as well as an index page in HAML using it)
      end

      def source_folder
        File.join(File.dirname(File.expand_path(__FILE__)), 'twitter_bootstrap_haml', '/')
      end

    end

    LocomotiveEditor::SiteTemplates::Manager.register(:twitter_bootstrap_haml, TwitterBootstrapHaml)

  end

end
