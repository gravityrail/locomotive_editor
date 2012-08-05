module LocomotiveEditor
  module Api

    class ContentEntry

      include HTTMultiParty
      include Api::Helpers

      attr_accessor :content_type, :content_type_service

      def initialize(auth_token, options = {})
        # see https://github.com/jwagener/httmultiparty/issues/11
        self.options    = options
        self.auth_token = auth_token
      end

      def list
        self.class.get("/content_types/#{self.content_type.slug}/entries.json", :query => { :auth_token => self.auth_token })
      end

      def create(params = {})
        # puts "---> create #{self.content_type.slug} / #{params.inspect} [QUERY]"
        self.class.post(
          "/content_types/#{self.content_type.slug}/entries.json",
          :query => { :auth_token => self.auth_token, :content_entry => params }
        )
      end

      def update(id, params = {})
        # puts "---> update #{self.content_type.slug} / #{id} / #{params.inspect}"
        self.class.put(
          "/content_types/#{self.content_type.slug}/entries/#{id}.json",
          :query => { :auth_token => self.auth_token, :content_entry => params }
        )
      end

      def show(permalink, content_type_slug = nil)
        slug = content_type_slug || self.content_type.slug
        self.class.get("/content_types/#{slug}/entries/#{permalink}.json", :query => { :auth_token => self.auth_token })
      end

      protected

      def label_for(entry)
        entry._permalink
      end

      def compare_entries(remote_entry, local_entry)
        remote_entry._slug == local_entry._permalink.downcase
      end

      def build_params(entry)
        entry.to_hash.tap do |hash|
          self.content_type.relationship_fields.each do |field|
            next if field.type == 'has_many'

            if field.type == 'belongs_to'
              entry_id = fetch_entry_id(entry.safe_attributes[field.name.to_sym], field.target_content_type)

              if entry_id
                hash["#{field.name}_id".to_sym] = entry_id
              end
            elsif field.type == 'many_to_many'
              hash["#{field.name.singularize}_ids".to_sym] = (entry.safe_attributes[field.name.to_sym] || []).map do |permalink|
                fetch_entry_id(permalink, field.target_content_type)
              end.compact
            end
          end
        end
      end

      def fetch_entry_id(permalink, content_type)
        self.show(permalink, content_type.slug)['_id']
      rescue
        nil
      end

    end

  end
end