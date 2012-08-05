module LocomotiveEditor

  module DeploySettings

    def self.read(target = :development)
      file, settings = nil, {}

      begin
        file = File.read(File.join(LocomotiveEditor.site_root, 'config', 'deploy.yml'))
      rescue
        raise 'No config/deploy.yml file found'
      end

      begin
        all_settings = YAML::load(file)
      rescue
        raise 'Malformed config.deploy.yml file'
      end

      settings = all_settings[target.to_s]

      if settings
        host      = settings.delete('host') || ''
        host      = "http://#{host}" unless host =~ /^http[s]?:\/\//
        base_path = settings.delete('base_path') || 'locomotive/api'

        settings['uri'] = File.join(host, base_path)

        OpenStruct.new(settings)
      else
        raise "Unknown target '#{target}' for the deployment"
      end
    end

  end

end
