require 'locomotive_editor/deploy_settings'
require 'locomotive_editor/template_reader'
require 'locomotive_editor/models'
require 'locomotive_editor/api'
require 'locomotive_editor/compass'
require 'coffee-script'

module LocomotiveEditor

  module Commands

    class Push < Base

      RESOURCES = %w(all theme_assets snippets content_types pages content_entries)

      def initialize(options)
        @options        = options
        @name           = @options[:name]
        @resource       = @options[:resource] || ''
        @target         = @options[:target]
        @only           = @options[:only]

        raise 'Can not push a resource without a site name' if @name.nil?
        raise "The resource is unknwon (ex: #{RESOURCES.join(', ')})" unless RESOURCES.include?(@resource)
        raise 'A target must be provided (ex: development, staging, production, ...etc)' if @target.blank?

        self.set_site

        self.sanitize_only_option

        @options[:locale] = LocomotiveEditor.current_site.default_locale
      end

      def run!
        puts %(... pushing "#{@resource}")

        settings = DeploySettings.read(@target)

        @token = Api::Token.get_one(settings.uri, settings.email, settings.password)

        Api::Base.base_uri settings.uri
        Api::ThemeAsset.base_uri settings.uri
        Api::ContentAsset.base_uri settings.uri
        Api::ContentEntry.base_uri settings.uri

        check_integrity

        case @resource.to_sym
        when :theme_assets    then push_theme_assets
        when :snippets        then push_snippets
        when :content_types   then push_content_types
        when :content_entries then push_content_entries
        when :pages           then push_pages
        when :all             then push_all
        end
      end

      protected

      def check_integrity
        site = Api::Site.new(@token, @options).show

        unless LocomotiveEditor.current_site.locales.all? { |l| site.locales.include?(l) }
          raise "Your site locales (#{LocomotiveEditor.current_site.locales.join(', ')}) do not match exactly the ones of your target (#{site.locales.join(', ')})"
        end

        if LocomotiveEditor.current_site.default_locale != site.locales.first
          raise "Your default site locale (#{LocomotiveEditor.current_site.default_locale}) is not the same as the one of your target (#{site.locales.first})"
        end
      end

      def push_all
        push_theme_assets ; push_snippets ; push_content_types ; push_pages; push_content_entries
      end

      def push_content_types
        service = Api::ContentType.new(@token, @options)

        service.push(LocomotiveEditor::Models::Site.first.content_types)
      end

      def push_content_entries
        LocomotiveEditor::Models::Site.first.content_types.each do |content_type|
          next unless include_resource?(content_type.slug)

          service = Api::ContentEntry.new(@token, @options)
          service.content_type = content_type

          service.push(content_type.contents || [])
        end
      end

      def push_pages
        LocomotiveEditor::Models::Base.reload!

        service = Api::Page.new(@token, @options)
        service.content_assets_service  = Api::ContentAsset.new(@token, @options)
        service.content_types_service   = Api::ContentType.new(@token)

        service.push(LocomotiveEditor::Models::Site.first.pages_with_layouts_first)
      end

      def push_snippets
        snippets = []

        Dir[File.join(LocomotiveEditor.site_root, 'app/views/snippets/*')].each do |file|
          next if File.directory?(file)

          name = File.basename(file, File.extname(file)).gsub('.liquid', '')
          snippet = OpenStruct.new({
            :name     => name.humanize,
            :slug     => name.parameterize('_'),
            :template => LocomotiveEditor::TemplateReader.read(file),
          })

          # get other translations
          LocomotiveEditor.current_site.locales_other_default.each do |locale|
            localized_file = File.join(File.dirname(file), locale, File.basename(file))
            if File.exists?(localized_file)
              (snippet.translations ||= {})[locale.to_s] = LocomotiveEditor::TemplateReader.read(localized_file).to_s
              # puts "localized_file = #{localized_file.inspect} / #{snippet.translations.values.inspect}"
            end
          end

          snippets << snippet
        end

        Api::Snippet.push(@token, snippets, @options)
      end

      def push_theme_assets
        service = Api::ThemeAsset.new(@token, @options)

        files = []

        # compile sass/scss files
        LocomotiveEditor::Compass.compile!

        Dir[File.join(LocomotiveEditor.site_root, 'public/**/*')].each do |file|
          entry     = file.gsub(LocomotiveEditor.site_root + '/public/', '')
          raw, type = nil, nil

          next if File.directory?(file) || entry =~ /^samples\// || File.basename(entry).starts_with?('_') || !include_resource?(file)

          if file.ends_with?('.scss') || file.ends_with?('.sass') # process sass/scss files
            entry = entry.gsub(/\.scss|\.sass/, '')
            file  = File.join(LocomotiveEditor.site_root, 'tmp', entry)
            # puts "target #{file.inspect}"
            # FileUtils.mv "#{file}.css", file
          elsif file.ends_with?('.coffee') # process coffeescript files
            entry = entry.gsub('.coffee', '')
            raw   = CoffeeScript.compile(File.read(file))
            type  = 'javascript'
          end

          files << OpenStruct.new({
            :folder         => File.dirname(entry),
            :filename       => File.basename(entry),
            :relative_path  => entry,
            :file           => file,
            :raw            => raw,
            :file_type      => type
          })
        end

        service.push(files)
      end


      def sanitize_only_option
        @only = @only.split(',') if @only
      end

      def include_resource?(name)
        return true if @only.blank?
        @only.any? { |_name| name.include?(_name) }
      end

      public

      def self.help_message
        """
Some examples:

* Push the theme assets to the Locomotive staging instance

  > locomotive_editor push -n awesome_website -r theme_assets -t staging

* Same command as previously but more verbose.

  > locomotive_editor push --name=awesome_website --resource=theme_assets --target=staging"""
      end

    end

  end

end