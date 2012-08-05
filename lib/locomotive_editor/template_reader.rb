require 'haml'

module LocomotiveEditor

  module TemplateReader

    def self.read(path)
      haml = !(path =~ /\.haml/).nil?
      path = "#{path}.liquid" unless path =~ /\.liquid/

      unless File.exists?(path)
        path = "#{path}.haml" # now, look for a haml version of the template
        haml = true if File.exists?(path)
      end

      return nil unless File.exists?(path)

      if haml
        template = File.read(path)
        template = template.force_encoding('UTF-8') if RUBY_VERSION =~ /1\.9/

        engine = Haml::Engine.new(template)
        engine.render
      else
        File.read(path)
      end
    end

  end

end