module LocomotiveEditor
  module Api

    class ThemeAsset

      include HTTMultiParty
      include Api::Helpers

      def initialize(token, options = {})
        self.options    = options
        # see https://github.com/jwagener/httmultiparty/issues/11
        self.auth_token = token
      end

      def list
        self.class.get('/theme_assets.json', :query => { :auth_token => self.auth_token })
      end

      def create(params = {})
        response = self.class.post(
          '/theme_assets.json',
          :query => { :auth_token => self.auth_token, :theme_asset => params }
        )

        params[:source].close if params[:source]

        response
      end

      def update(id, params = {})
        response = self.class.put(
          "/theme_assets/#{id}.json",
          :query => { :auth_token => self.auth_token, :theme_asset => params }
        )

        params[:source].close if params[:source]

        response
      end

      protected

      def label_for(entry)
        entry.relative_path
      end

      def build_params(entry)
        { :folder => entry.folder, :auth_token => self.auth_token }.tap do |params|
          if entry.raw.nil?
            params[:source] = File.new(entry.file)
          else
            params.merge!({
              :performing_plain_text  => true,
              :plain_text_type        => entry.file_type,
              :plain_text_name        => entry.filename,
              :plain_text             => entry.raw
            })
          end
        end
      end

      def compare_entries(remote_entry, local_entry)
        path = File.join(remote_entry.folder, File.basename(remote_entry.local_path))
        path == local_entry.relative_path
      end

    end

  end
end