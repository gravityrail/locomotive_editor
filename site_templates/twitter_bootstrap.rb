module LocomotiveEditor

  module SiteTemplates

    class TwitterBootstrap < Template

      def self.message
        %(includes all the files provided by the Twitter Bootstrap package as well as an index page using it)
      end

      def source_folder
        File.join(File.dirname(File.expand_path(__FILE__)), 'twitter_bootstrap', '/')
      end

    end

    LocomotiveEditor::SiteTemplates::Manager.register(:twitter_bootstrap, TwitterBootstrap)

  end

end
