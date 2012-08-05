module LocomotiveEditor
  module Models

    class Page < Base

      attr_accessor :_id, :title, :fullpath, :handle, :template_path, :published,
                    :templatized, :model, :position, :redirect_url, :listed,
                    :seo_title, :meta_keywords, :meta_description, :parent_id, :target_klass_name,
                    :translations, :site

      def initialize(attributes = {})
        super

        if self.title.blank?
          if self.templatized?
            self.title = 'Template'
          else
            self.title = File.basename(self.fullpath.to_s).humanize
          end
        end
      end

      def fullpath(locale = nil)
        localized_attribute :fullpath, locale
        # if self.templatized?
        #   path.gsub(/\/template$/, '/content_type_template')
        # else
        #   path
        # end
      end

      def title(locale = nil)
        localized_attribute :title, locale
      end

      def template_path(locale = nil)
        locale  ||= I18n.locale.to_s
        path    = localized_attribute(:fullpath, locale)
        if self.site.default_locale.to_s == locale
          path
        else
          File.join(locale, path)
        end
      end

      def depth
        if self.fullpath == 'index'
          0
        else
          self.fullpath.split('/').size
        end
      end

      def redirect?
        self.redirect_url.present?
      end

      alias :redirect :redirect?

      def published?
        self.published.nil? ? true : self.published
      end

      def listed?
        self.listed.nil? ? true : self.listed
      end

      def slug
        File.basename(self.fullpath)
      end

      def templatized?
        self.templatized == true || !@content_type.blank? || self.fullpath =~ /content_type_template/

        # unless _templatized
        #   puts "self.parent_path = #{self.parent_path}"
        #   # _parent = Site.first.lookup_page(self.parent_path, false)
        #   # _parent = self.parent
        #
        #   # puts "_parent = #{self.parent}"
        #
        #   # while _parent do
        #   #   if _parent.templatized == true
        #   #     self.model = _parent.model
        #   #     _templatized = true
        #   #     break
        #   #   end
        #   #   _parent = _parent.parent
        #   # end
        # end

        # _templatized
      end

      def layout?
        self.layout_path.nil?
      end

      def layout_path
        self.raw_template =~ /\{%\s*extends\s+\'?([[\w|\-|\_]|\/]+)\'?\s*%\}/
        $1
      end

      def persisted?
        !self._id.blank?
      end

      def content_type
        if @model.nil? && self.templatized?
          segments      = self.fullpath.split('/')
          index         = segments.index('content_type_template')
          parent        = Site.first.lookup_page(segments.slice(0..index).join('/'), false)
          @content_type = parent.content_type
        end

        @content_type ||= Site.first.lookup_content_type(@model)
      end

      def raw_template(locale = nil)
        path = File.join(LocomotiveEditor.site_templates_root, self.template_path(locale))
        @raw_template ||= LocomotiveEditor::TemplateReader.read(path)
      end

      def parent_path
        return nil if %w(index 404).include?(self.template_path)

        segments = self.template_path.split('/')

        if segments.size == 1
          segments = ['index']
        else
          segments.pop
        end

        segments.join('/')
      end

      def parent
        Site.first.lookup_page(self.class.parent_template_path(self.template_path), false)
      end

      def children
        local_root = self.fullpath

        if !File.exists?(File.join(LocomotiveEditor.site_templates_root, fullpath)) # no folder ?
          return [] if self.slug != 'index'

          # FIXME: not sure about the following piece of code. What was its purpose ???????
          (segments = self.fullpath.split('/')).pop
          local_root = segments.join('/')
        end

        list = Dir[File.join(LocomotiveEditor.site_templates_root, local_root, '*.liquid*')].map do |template_path|
          child_fullpath = template_path.gsub(LocomotiveEditor.site_templates_root, '').gsub(/^\//, '').gsub('.liquid', '').gsub('.haml', '')

          Site.first.lookup_page(child_fullpath)
        end.compact.delete_if { |p| %w{index 404}.include?(p.fullpath) || p.templatized? }

        # add pages without liquid templates (redirect page)
        Site.first.lookup_pages(local_root).each do |page|
          list << page if page.redirect?
        end

        list.uniq.sort_by(&:position)
      end

      def render(context)
        ::Liquid::Template.parse(self.raw_template, { :page => self }).render(context)
      end

      def fetch_content_type_entry(path)
        %r(^#{self.fullpath.gsub('content_type_template', '([^\/]+)')}$) =~ path

        permalink = $1

        self.content_type.lookup_content(permalink)
      end

      def to_hash
        default_attributes = %w(title slug fullpath templatized position redirect redirect_url seo_title meta_keywords meta_description raw_template)
        default_attributes << 'parent_id' unless self.parent_id.blank?
        default_attributes << 'target_klass_name' unless self.target_klass_name.blank?
        default_attributes << 'handle' unless self.handle.blank?
        default_attributes.inject({}) { |memo, attribute| memo[attribute] = self.send(attribute.to_sym); memo }.tap do |hash|
          hash['published'] = self.published?
          hash['listed']    = self.listed?
        end
      end

      def to_liquid
        LocomotiveEditor::Liquid::Drops::Page.new(self)
      end

      def self.parent_template_path(template_path)
        segments = template_path.split('/')

        if segments.size == 1
          'index'
        else
          segments.pop

          # if File.exists?(File.join(LocomotiveEditor.site_templates_root, "#{segments.join('/')}.liquid"))
            segments.join('/')
          # else
            # self.parent_template_path(segments.join('/'))
          # end
        end
      end

      def self.path_combinations(path)
        _path_combinations(path.split('/'))
      end

      def self._path_combinations(segments, can_include_template = true)
        return nil if segments.empty?

        segment = segments.shift

        (can_include_template ? [segment, 'content_type_template'] : [segment]).map do |_segment|
          if (_combinations = _path_combinations(segments.clone, can_include_template && _segment != 'content_type_template'))
            [*_combinations].map do |_combination|
              File.join(_segment, _combination)
            end
          else
            [_segment]
          end
        end.flatten
      end

      protected

      def localized_attribute(attribute, locale = nil)
        locale ||= I18n.locale
        value   = instance_variable_get(:"@#{attribute.to_s}")
        # puts "localized_attribute(#{attribute}, #{locale}, #{value.inspect})"
        if self.translations && self.translations[locale.to_s]
          # puts "self.translations[#{locale.inspect}] = #{self.translations[locale.to_s].inspect}"
          self.translations[locale.to_s][attribute.to_s] || value
        else
          # puts "keeping the original one: #{value}"
          value
        end
      end

    end

  end
end