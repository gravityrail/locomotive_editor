module LocomotiveEditor
  module Models

    class Base

      @@source = nil

      def initialize(attributes = nil)
        attributes ||= {}
        attributes.each do |key, value|
          if self.respond_to?(key.to_sym)
            self.send("#{key}=", value)
          end
        end
      end

      def self.source
        return @@source if @@source.present?

        config_path = File.join(LocomotiveEditor.site_root, 'config', 'site.yml')

        # pull in the config_yaml
        config_raw = File.read(config_path).strip if File.exists?(config_path)

        if File.exists?(File.join(LocomotiveEditor.site_root, 'database.yml'))
          raise "[WARNING] database.yml is deprecated. Run \"locomotive upgrade -n <your website>\" in your shell."
        end

        config_raw = <<-END if config_raw.blank?
site:
  name: "Acme website"
  locale: en

  pages:
    - "index":
      title: Home page
    - "404":
      title: Page not found
  END

        @@source = YAML::load(config_raw)

        @@source['site'].merge!(self.fetch_content_types)

        @@source
      end

      def self.reload!
        @@source = nil
        @@first = nil
      end

      def self.first
        key = self.name.demodulize.underscore
        @@first ||= self.new(self.source[key])
      end

      protected

      def self.fetch_content_types
        type_key, data_key = 'content_types', 'contents' # dealing with String is safer

        config_yaml = { type_key => {} }

        Dir[File.join(LocomotiveEditor.site_root, 'app', 'content_types', '*.yml')].each do |config_path|
          name = File.basename(config_path, '.yml').downcase

          local_config_yaml = YAML.load_file config_path

          config_yaml[type_key][name] = local_config_yaml

          # look up for data
          data_path = File.join(LocomotiveEditor.site_root, 'data', File.basename(config_path))

          if File.exists?(data_path)
            data_yaml = YAML.load_file data_path

            config_yaml[type_key][name][data_key] = data_yaml
          end
        end

        config_yaml
      end

    end
  end

end
