module LocomotiveEditor
  module Models

    class ContentField < Base

      attr_accessor :_id, :label, :name, :type, :hint, :position, :target, :required, :localized, :class_name, :inverse_of, :select_options, :text_formatting, :_destroy

      def initialize(attributes = {})
        attributes.symbolize_keys!

        super

        self.label ||= self.name
        (self.type ||= 'string').downcase!

        self.select_options = (self.select_options || []).map { |o| OpenStruct.new(:name => o) }
      end

      def target_content_type
        # available only if the field is from a has_one / has_many type
        Site.first.lookup_content_type(self.target)
      end

      def lookup_select_option(name)
        self.select_options.detect { |o| o.name == name && o._id.nil? }
      end

      def is_relationship?
        %w(belongs_to has_many many_to_many).include?(self.type)
      end

      def to_hash
        default_attributes = %w(label name type hint position required localized)
        default_attributes.inject({}) { |memo, attribute| memo[attribute] = self.send(attribute.to_sym); memo }.tap do |hash|
          hash['_id']       = self._id unless self._id.blank?
          hash['_destroy']  = self._destroy unless self._destroy.blank?
          hash['select_options_attributes'] = self.select_options.map(&:marshal_dump) unless self.select_options.empty?

          case self.type
          when 'text'
            hash['text_formatting'] = self.text_formatting
          when 'belongs_to'
            hash['class_name'] = self.class_name
          when 'has_many', 'many_to_many'
            hash['class_name'] = self.class_name
            hash['inverse_of'] = self.inverse_of
          end
        end
      end

    end

  end
end