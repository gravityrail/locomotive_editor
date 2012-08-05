module LocomotiveEditor
  module Liquid
    class SnippetFileSystem < ::Liquid::LocalFileSystem

      def read_template_file(template_path)
        template = nil

        full_path(template_path).each do |path|
          template = TemplateReader.read(path)
          break unless template.nil?
        end

        if template.nil?
          raise ::Liquid::FileSystemError, "No such snippet template '#{template_path}' (#{I18n.locale})"
        else
          template
        end
        #
        # begin
        #   TemplateReader.read(full_path)
        # rescue Errno::ENOENT => e
        #   raise ::Liquid::FileSystemError, "No such snippet template '#{template_path}' (#{I18n.locale})"
        # end
      end

      def full_path(template_path)
        raise ::Liquid::FileSystemError, "Illegal snippet name '#{template_path}'" unless template_path =~ /^[a-zA-Z0-9_\/]+$/

        # full_path = if LocomotiveEditor.current_site.default_locale.to_s == I18n.locale.to_s
        #   File.join(root, "#{template_path}.liquid")
        # else
        #   File.join(root, I18n.locale.to_s, "#{template_path}.liquid")
        # end

        [File.join(root, I18n.locale.to_s, "#{template_path}.liquid"), File.join(root, "#{template_path}.liquid")]


        # raise ::Liquid::FileSystemError, "Illegal template path '#{File.expand_path(full_path)}'" unless File.expand_path(full_path) =~ /^#{File.expand_path(root)}/

        # full_path
      end

    end
  end
end