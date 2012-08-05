# %w{. tags drops filters}.each do |dir|

require 'locomotive_editor/liquid/drops/base'

module Liquid
  class Drop
    def site
      @context.registers[:site]
    end
  end

  class Template

    # creates a new <tt>Template</tt> object from liquid source code
    def parse_with_utf8(source, context = {})
      if RUBY_VERSION =~ /1\.9/
        source = source.force_encoding('UTF-8') if source.present?
      end
      self.parse_without_utf8(source, context)
    end

    alias_method_chain :parse, :utf8

  end
end

%w{. drops tags filters}.each do |dir|
  Dir[File.join(File.dirname(__FILE__), 'liquid', dir, '*.rb')].each { |lib| require lib }
end

::Liquid::Template.file_system = LocomotiveEditor::Liquid::TemplateFileSystem.new(LocomotiveEditor.site_templates_root)
