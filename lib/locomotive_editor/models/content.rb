module LocomotiveEditor
  module Models

    class Content < Base

      attr_accessor :_id, :value, :seo_title, :meta_keywords, :meta_description, :_permalink

      def initialize(attributes = {})
        @errors       = {}
        @value        = attributes[:_label]
        @attributes   = attributes
        @content_type = @attributes.delete(:content_type)
        @fields       = @content_type.fields
        %w(_permalink seo_title meta_keywords meta_description).each do |attribute|
          self.send(:"#{attribute}=", attributes[attribute.to_sym])
        end
      end

      def highlighted_field_value
        @value
      end

      def _permalink
        (@_permalink || @value).parameterize('-')
      end

      alias :slug :_permalink

      def method_missing(meth, *args)
        if @content_type.label_field_name.to_s == meth.to_s
          @value
        elsif field = @fields.detect { |f| f.name == meth.to_s }
          value = @attributes[meth]

          case field.type.downcase
          when 'string', 'text', 'select', 'boolean', 'select' then value
          when 'date' then value.is_a?(String) ? Date.parse(value) : value
          when 'file' then { 'url' => @attributes[meth] }
          when 'belongs_to' then
            if field.target_content_type
              field.target_content_type.contents.detect { |c| c.highlighted_field_value == value }
            else
              LocomotiveEditor::Logger.warn "unknow content type #{field.target} for the '#{field.name}' has_one relationship"
            end
          when 'has_many' then
            if field.target_content_type
              field.target_content_type.contents.find_all { |c| [self.highlighted_field_value, self._permalink].include?(c.safe_attributes[field.inverse_of.to_sym])  }
            else
              LocomotiveEditor::Logger.warn "unknow content type #{field.target} for the '#{field.name}' has_many relationship"
            end
          when 'many_to_many' then
            if field.target_content_type
              field.target_content_type.contents.find_all { |c| (value || []).include?(c.highlighted_field_value) || (value || []).include?(c._permalink) }
            else
              LocomotiveEditor::Logger.warn "unknow content type #{field.target} for the '#{field.name}' many_to_many relationship"
            end
          end
        else
          LocomotiveEditor::Logger.error "#{meth} is not a property of #{@content_type.name}"
        end
      end

      def safe_attributes # remove default proc
        hash = {}
        @attributes.each { |k, v| hash[k] = v }
        hash
      end

      def valid?
        self.errors.blank?
      end

      def errors
        @errors = {}

        @content_type.fields.each do |field|
          @errors[field.name.to_sym] = I18n.t('errors.messages.blank') if @attributes[field.name.to_sym].blank?
        end

        @errors.blank? ? nil : @errors
      end

      def translations; nil; end
      def delete_field; nil; end

      def to_hash
        hash = { :seo_title => self.seo_title, :meta_keywords => self.meta_keywords, :meta_description => self.meta_description, :_permalink => self._permalink }

        @fields.each do |field|
          next if field.is_relationship?

          if field.type == 'file'
            next if (@attributes[field.name.to_sym] || '').strip.empty?

            filepath = File.join(LocomotiveEditor.site_root, 'public', @attributes[field.name.to_sym])

            hash[field.name.to_sym] = File.new(filepath)
          else
            hash[field.name.to_sym] = self.send(field.name.to_sym)
          end
        end

        hash.reject { |k, v| v.nil? }
      end

      def to_liquid
        LocomotiveEditor::Liquid::Drops::Content.new(self)
      end

    end

  end
end