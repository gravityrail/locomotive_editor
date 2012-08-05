module LocomotiveEditor
  module Liquid
    class TemplateFileSystem < ::Liquid::LocalFileSystem

      def read_template_file(template_path)
        full_path = full_path(template_path)

        begin
          TemplateReader.read(full_path)
        rescue Errno::ENOENT => e
          raise ::Liquid::FileSystemError, "No such template '#{template_path}'"
        end
      end

      def full_path(template_path)
        raise ::Liquid::FileSystemError, "Illegal template name '#{template_path}'" unless template_path =~ /^[^.\/][a-zA-Z0-9_\/]+$/

        full_path = if template_path.include?('/')
          File.join(root, File.dirname(template_path), "#{File.basename(template_path)}.liquid")
        else
          File.join(root, "#{template_path}.liquid")
        end

        raise ::Liquid::FileSystemError, "Illegal template path '#{File.expand_path(full_path)}'" unless File.expand_path(full_path) =~ /^#{File.expand_path(root)}/

        full_path
      end

    end
  end
end