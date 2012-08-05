module LocomotiveEditor
  module Api

    class ContentType < Base

      attr_accessor :all_content_types, :content_types_with_relationships

      def list
        self.class.get('/content_types.json')
      end

      def create(params = {})
        self.class.post(
          '/content_types.json',
          :body => { :content_type => params }
        )
      end

      def update(id, params = {})
        self.class.put(
          "/content_types/#{id}.json",
          :body => { :content_type => params }
        )
      end

      def push(entries)
        super

        # deal with content_types including relationships
        return if self.content_types_with_relationships.blank?

        self.content_types_with_relationships.each do |entry|
          self.update(entry._id, entry.to_hash_for_relationships(self.all_entries))
        end
      end

      def push_entry(entry)
        super(entry).tap do |response|
          if response && entry.has_relationship?
            (self.content_types_with_relationships ||= []) << entry
          end
        end
      end

      protected

      def label_for(entry)
        entry.name
      end

      def merge_entry(remote_entry, local_entry)
        local_entry._id = remote_entry._id

        remote_entry.entries_custom_fields.each do |remote_field|
          field = local_entry.lookup_field(remote_field['name'])
          _id   = remote_field['_id']

          if field.nil?
            local_entry.fields << LocomotiveEditor::Models::ContentField.new(:_id => _id, :_destroy => true)
          else
            field._id = _id

            if field.type == 'select'
              select_options = field.select_options
              (remote_field['select_options'] || []).each do |remote_select_option|
                select_option = field.lookup_select_option(remote_select_option['name'])
                _id           = remote_select_option['_id']

                if select_option.nil?
                  field.select_options << OpenStruct.new({ :_id => _id, :_destroy => true })
                else
                  select_option._id = _id
                end
              end
            end
          end
        end
      end

      def build_params(entry)
        entry.to_hash
      end

      def compare_entries(remote_entry, local_entry)
        remote_entry.slug == local_entry.slug
      end

    end

  end
end