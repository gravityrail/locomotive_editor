module LocomotiveEditor
  module Models

    class ContentType < Base

      attr_accessor :_id, :name, :slug, :description, :group_by, :order_by, :order_by_direction, :public_submission_enabled, :label_field_name, :contents, :fields, :raw_item_template, :priority

      def initialize(attributes = {})
        self.fields = attributes.delete(:fields)

        super
      end

      def fields=(list)
        return unless list.respond_to?(:[])

        @fields = list.map { |attributes| ContentField.new(attributes.values.first.merge(:name => attributes.keys.first)) }
      end

      def ordered_fields
        (@fields || []).each_with_index do |field, index|
          field.position ||= index
        end
      end

      def relationship_fields
        self.ordered_fields.find_all { |f| f.is_relationship? }
      end

      def without_relationship_fields
        self.ordered_fields.find_all { |f| !f.is_relationship? }
      end

      def contents=(list)
        return unless list.respond_to?(:[])

        @contents = list.map do |data|
          value, attributes = data.is_a?(Array) ? [data.first, data.last] : [data.keys.first, data.values.first]

          self.build_content(attributes.merge(:_label => value))
        end
      end

      def build_content(attributes)
        attributes.symbolize_keys!
        Content.new(attributes.merge(:content_type => self))
      end

      def add_content(attributes)
        @contents ||= []

        content = self.build_content(attributes)

        @contents << content

        content
      end

      def lookup_content(slug)
        @contents.detect { |c| c._permalink == slug }
      end

      def lookup_field(name)
        @fields.detect { |f| f.name == name }
      end

      def group_contents_by(slug)
        @contents.group_by { |c| c.send(slug.to_sym) }.to_a.collect do |group|
          { :name => group.first, :entries => group.last }.with_indifferent_access
        end
      end

      def select_names(field)
        @contents.map { |c| c.send(field.to_sym) }.uniq
      end

      def has_relationship?
        @fields.any? { |f| f.is_relationship? }
      end

      def to_hash
        default_attributes = %w(name slug description group_by order_by order_by_direction public_submission_enabled label_field_name raw_item_template)
        default_attributes.inject({}) { |memo, attribute| memo[attribute] = self.send(attribute.to_sym); memo }.tap do |hash|
          hash['order_by'] = '_position' if self.order_by == 'manually'
          hash['entries_custom_fields_attributes'] = self.without_relationship_fields.map(&:to_hash)
        end
      end

      def to_hash_for_relationships(all_content_types)
        {
          'entries_custom_fields_attributes' => self.relationship_fields.map do |field|
            content_type = all_content_types.detect { |ct| ct.slug == field.target }
            field.class_name = "Locomotive::Entry#{content_type._id}"
            field.to_hash
          end
        }
      end

    end

  end
end