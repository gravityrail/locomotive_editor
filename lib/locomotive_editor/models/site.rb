module LocomotiveEditor
  module Models

    class Site < Base

      attr_accessor :name, :seo_title, :meta_keywords, :meta_description, :locale, :content_types, :locales

      def initialize(attributes = {})
        self.locales = attributes.delete('locales')

        I18n.locale = self.default_locale

        super
      end

      def locales=(values)
        @locales = values || ['en']
      end

      def default_locale
        self.locales.first
      end

      def locales_other_default
        self.locales - [self.default_locale]
      end

      def locales_to_regexp
        /^\/(#{(self.locales).join('|')})\//
      end

      def content_types=(list)
        return unless list.respond_to?(:[])
        @content_types = list.map do |attributes|
          _attributes = attributes.last.symbolize_keys
          _attributes[:name] = attributes.first if _attributes[:name].blank?
          ContentType.new(_attributes)
        end.sort { |a, b| b.priority || 0 <=> a.priority || 0 }
      end

      def lookup_content_type(slug)
        self.content_types.detect { |c| c.slug == slug }
      end

      def layouts
        self.pages.any? { |page| page.layout? }
      end

      def non_layout_pages
        self.pages.any? { |page| !page.layout? }
      end

      def pages
        @pages || []
      end

      def pages=(list)
        return unless list.respond_to?(:[])

        @pages = list.map do |data|
          fullpath, attributes = data.is_a?(Array) ? [data.first.to_s, data.last] : [data.keys.first.to_s, data.values.first]

          Page.new((attributes || {}).merge(:site => self, :fullpath => fullpath))
        end

        Dir[File.join(LocomotiveEditor.site_templates_root, '**/*.liquid*')].each do |template_path|
          fullpath = template_path.gsub(LocomotiveEditor.site_templates_root, '').gsub(/^\//, '').gsub('.liquid', '').gsub('.haml', '')

          next if fullpath =~ /^(#{self.locales.join('|')})\//

          self.add_page(fullpath)
        end

        @pages.each_with_index { |p, position| p.position = position }
      end

      def lookup_pages(path)
        if path.respond_to?(:blank?)
          path = path.blank? ? /^[^\/]+$/ : /^#{path}\/[^\/]+$/
        end

        self.pages.find_all { |p| p.fullpath =~ path }
      end

      def lookup_page(fullpath, force = true)
        page = self.pages.detect { |p| [*fullpath].include?(p.fullpath) }

        if page.nil? && force
          [*fullpath].each do |path|
            next if path =~ /content_type_template$/

            if  File.exists?(File.join(LocomotiveEditor.site_templates_root, "#{path}.liquid")) ||
                File.exists?(File.join(LocomotiveEditor.site_templates_root, "#{path}.liquid.haml"))
              page = self.add_page(path)
            else
              puts "does not exist #{File.join(LocomotiveEditor.site_templates_root, path)}"
            end
          end
        end

        page
      end

      def lookup_page_by_handle(handle)
        self.pages.detect { |p| [*handle].include?(p.handle) }
      end

      def pages_with_layouts_first
        list = []

        without_a_layout = self.pages.find_all { |p| p.layout? }

        list += without_a_layout

        with_a_direct_layout = without_a_layout.collect do |page|
          self.all_pages_with_a_layout(page.fullpath)
        end.flatten

        list += with_a_direct_layout

        others = (self.pages - list).sort { |a, b| a.depth <=> b.depth }

        self.build_missing_parents(list + others)
      end

      def all_pages_with_a_layout(layout_path)
        list = self.pages.find_all { |p| p.layout_path == layout_path }

        list + list.collect { |p| self.all_pages_with_a_layout(p.fullpath) }
      end

      def build_missing_parents(pages)
        with_missing_parents = pages.clone
        pages.collect do |page|
          list = self._build_missing_parent(page, with_missing_parents)
          with_missing_parents += list
          list << page
        end.flatten
      end

      def _build_missing_parent(page, pages)
        parent_path = page.parent_path
        parent      = pages.detect { |_entry| _entry.fullpath == parent_path }

        if parent
          self._build_missing_parent(parent, pages)
        elsif !parent_path.blank?
          parent = LocomotiveEditor::Models::Page.new({
            :site     => page.site,
            :listed   => false,
            :fullpath => parent_path
          })
          [parent] + self._build_missing_parent(parent, pages)
        else
          []
        end
      end

      def add_page(fullpath)
        # perhaps, the page is templatized?, to be sure, we use the template_path property instead
        return nil if self.pages.detect { |p| p.template_path == fullpath }

        page = Page.new({
          :site     => self,
          :title    => File.basename(fullpath).humanize,
          :fullpath => fullpath.to_s
        })

        self.pages << page

        page
      end

      def to_liquid
        LocomotiveEditor::Liquid::Drops::Site.new(self)
      end

    end

  end
end