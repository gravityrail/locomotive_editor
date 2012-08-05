module LocomotiveEditor

  module Commands

    class Create < Base

      def initialize(options)
        @options        = options
        @name           = @options[:name]
        @folder         = @name.parameterize('_') rescue nil
        @template_name  = @options[:template] || 'empty'

        raise 'Can not create a site without a name' if @name.nil?
        raise 'The folder is not valid' if @folder.blank?
        raise 'A site with the same name already exists' if File.directory?(@folder) && !@options[:force]

        LocomotiveEditor.require_ext_loader

        template_klass = LocomotiveEditor::SiteTemplates::Manager.get(@template_name)
        raise "Unknown site template: #{@template_name}" if template_klass.nil?

        LocomotiveEditor.site = @folder

        @template = template_klass.new(@name, @folder, @options)
      end

      def run!
        puts %(... creating the "#{@name}" site)

        @template.create!

        puts "\n\nYour site named \"#{@name}\" has been created with success. You can edit the whole site here:\n #{File.expand_path(@folder)}\n\n"
      end

      def self.help_message
        """
Some examples:

* Create an empty website (use the default site template)

  > locomotive_editor create -n awesome_website

* Create a website with Twitter bootstrap enabled

  > locomotive_editor create -n awesome_website -t twitter_bootstrap_haml

* Same command as previously but more verbose.

  > locomotive_editor create -n awesome_website --template=twitter_bootstrap_haml"""
      end

    end

  end

end