module LocomotiveEditor
  module DragonflyExt

    @@enabled = nil

    def self.setup!
      return @@enabled unless @@enabled.nil?

      begin
        require 'rack/cache'
        require 'RMagick'
        require 'dragonfly'

        ## initialize Dragonfly ##
        app = ::Dragonfly[:images].configure_with(:imagemagick)

        ## configure it ##
        ::Dragonfly[:images].configure do |c|
          convert = `which convert`.strip.presence || '/usr/local/bin/convert'
          c.convert_command  = convert
          c.identify_command = convert

          c.allow_fetch_url  = true
          c.allow_fetch_file = true

          c.url_format = '/images/dynamic/:job/:basename.:format'
        end

        LocomotiveEditor::Logger.info 'Dragonfly enabled'

        @@enabled = true
      rescue Exception => e
        LocomotiveEditor::Logger.info 'Dragonfly disabled'
        @@enabled = false
      end
    end

    def self.enabled?
      @@enabled == true
    end

    def self.resize_url(source, resize_string)
      _source = (case source
      when String then source
      when Hash   then source['url'] || source[:url]
      else
        source.try(:url)
      end)

      if _source.blank?
        LocomotiveEditor::Logger.error "Unable to resize on the fly: #{source.inspect}"
        return
      end

      return _source unless self.enabled?

      if _source =~ /^http/
        file = self.app.fetch_url(_source)
      else
        file = self.app.fetch_file(File.join(LocomotiveEditor.site_root, 'public', _source))
      end

      file.process(:thumb, resize_string).url
    end

    def self.app
      ::Dragonfly[:images]
    end

  end
end