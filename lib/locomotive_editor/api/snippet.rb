module LocomotiveEditor
  module Api

    class Snippet < Base

      def list
        self.class.get('/snippets.json')
      end

      def create(params = {}, extra_params = {})
        self.class.post(
          '/snippets.json',
          :body => { :snippet => params }.merge(extra_params)
        )
      end

      def update(id, params = {}, extra_params = {})
        self.class.put(
          "/snippets/#{id}.json",
          :body => { :snippet => params }.merge(extra_params)
        )
      end

      def push_translated_entry(entry, value, locale)
        response = self.update(entry._id, { :template => value }, { :locale => locale })
        output entry, response, false, locale
      end

      protected

      def label_for(entry)
        entry.slug
      end

      def compare_entries(remote_entry, local_entry)
        remote_entry.slug == local_entry.slug
      end

    end

  end
end