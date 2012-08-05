module LocomotiveEditor
  module Liquid
    module Tags
      class Extends < ::Liquid::Extends

        def parse_parent_template
          if @template_name == 'parent'
            # @template_name = LocomotiveEditor::Models::Page.parent_template_path(@context[:page].template_path)
            @template_name = LocomotiveEditor::Models::Page.parent_template_path(@context[:page].fullpath)
            # segments = @context[:page].fullpath.split('/')
            # segments.pop
            # @template_name = segments.join('/')
            # puts "@template_name = #{@template_name.inspect} / #{@context[:page].template_path}"
          end

          page = LocomotiveEditor::Models::Site.first.lookup_page(@template_name)

          ::Liquid::Template.parse(page.raw_template, { :page => page })
        end

      end

      ::Liquid::Template.register_tag('extends', Extends)
    end
  end
end