module LocomotiveEditor

  module Commands

    class Upgrade < Base

      def initialize(options)
        @options = options
        @name = @options[:name]

        raise 'Error: This command can only be applied to site folder. Use the -n or --name to pass the name of the site' if @name.blank?

        LocomotiveEditor.settings['site_root'] = File.expand_path(File.join('.', @name))

        if !File.exists?(File.join(LocomotiveEditor.site_root, 'database.yml'))
          raise 'This site is up-to-date'
        end
      end

      def run!
        puts "... Upgrading \"#{@name}\" site"

        config_yaml = YAML::load(File.read(File.join(LocomotiveEditor.site_root, 'database.yml')))

        self.generate_files_structure

        # generating all the content types file
        self.generate_content_types_files(config_yaml)

        # asset collections become now content types
        self.migrate_asset_collections(config_yaml)

        # move templates / snippets folders to their new place (app/views)
        self.move_templates_and_snippets

        puts "generating config/site.yml"
        config_yaml['site'].delete('assets')
        File.open(File.join(LocomotiveEditor.site_root, 'config', 'site.yml'), 'w') do |f|
          f.write(yaml(config_yaml))
        end

        puts "moving database.yml into config/database_archived.yml"
        FileUtils.mv(File.join(LocomotiveEditor.site_root, 'database.yml'), File.join(LocomotiveEditor.site_root, 'config', 'database_archived.yml'))

        puts "\n\nYour site named \"#{@name}\" has been upgraded with success.\n\n"
      end

      protected

      def generate_files_structure
        %w(app/views app/content_types data config).each do |folder|
          puts "creating...#{folder}"
          FileUtils.mkdir_p File.join(LocomotiveEditor.site_root, folder)
        end
      end

      def move_templates_and_snippets
        if File.exists?(File.join(LocomotiveEditor.site_root, 'templates'))
          puts "moving...templates to app/views/pages"
          FileUtils.mv(File.join(LocomotiveEditor.site_root, 'templates'), File.join(LocomotiveEditor.site_root, 'pages'))
          FileUtils.mv(File.join(LocomotiveEditor.site_root, 'pages'), File.join(LocomotiveEditor.site_root, 'app', 'views', '.'))
        end

        if File.exists?(File.join(LocomotiveEditor.site_root, 'snippets'))
          puts "moving...snippets to app/views/snippets"
          FileUtils.mv(File.join(LocomotiveEditor.site_root, 'snippets'), File.join(LocomotiveEditor.site_root, 'app', 'views', '.'))
        end
      end

      def generate_content_types_files(config)
        content_types = config['site'].delete('content_types')

        (content_types || []).each do |name, attributes|
          filename = attributes['slug'].slugify

          data = attributes.delete('contents')

          unless data.blank?
            puts "generating data/#{filename}.yml"

            File.open(File.join(LocomotiveEditor.site_root, 'data', "#{filename}.yml"), 'w') do |f|
              f.write(yaml(data))
            end
          end

          puts "generating app/content_types/#{filename}.yml"

          File.open(File.join(LocomotiveEditor.site_root, 'app', 'content_types', "#{filename}.yml"), 'w') do |f|
            f.write("name: #{name}\n")
            f.write(yaml(attributes))
          end
        end
      end

      def migrate_asset_collections(config)
        collections = config['site'].delete('asset_collections')

        (collections || []).each do |name, attributes|
          filename = attributes['slug'].slugify

          data = attributes.delete('assets')

          if File.exists?(File.join(LocomotiveEditor.site_root, 'data', "#{filename}.yml"))
            puts '[WARNING] rename your asset collection (just change the slug) because a content type has the exact same name.'
            next
          end

          unless data.blank?
            puts "generating data/#{filename}.yml"

            data.each do |hash| # replace url by source
              url = hash.values.first.delete('url')
              hash.values.first['source'] = url
            end

            File.open(File.join(LocomotiveEditor.site_root, 'data', "#{filename}.yml"), 'w') do |f|
              f.write(yaml(data))
            end
          end

          attributes['fields'] ||= []
          attributes['fields'].insert(0, { 'name' => { 'label' => 'Name', 'kind' => 'string', 'required' => true, 'hint' => 'Name of your asset' } })
          attributes['fields'].insert(1, { 'source' => { 'label' => 'Source', 'kind' => 'file', 'required' => true } })

          File.open(File.join(LocomotiveEditor.site_root, 'app', 'content_types', "#{filename}.yml"), 'w') do |f|
            f.write("name: #{name}\n")
            f.write("highlighted_field_name: name\n")
            f.write("order_by: manually\n")
            f.write(yaml(attributes))
          end
        end
      end

    end

  end

end