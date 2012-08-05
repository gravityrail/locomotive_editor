module LocomotiveEditor
  module Api

    class ContentAsset

      include HTTMultiParty
      include Api::Helpers

      def initialize(auth_token, options = {})
        # see https://github.com/jwagener/httmultiparty/issues/11
        self.options    = options
        self.auth_token = auth_token
      end

      def list
        self.class.get('/content_assets.json', :query => { :auth_token => self.auth_token })
      end

      def create(params = {})
        self.class.post(
          '/content_assets.json',
          :query => { :auth_token => self.auth_token, :content_asset => params }
        )
      end

      # FIXME: there is no need to modify the file
      def update(id, params = {})
        # self.class.put(
        #   "/content_assets/#{id}.json",
        #   :query => { :auth_token => self.auth_token, :content_asset => params }
        # )
      end

      def push_entry(relative_filepath)
        filepath = File.join(LocomotiveEditor.site_root, 'public', relative_filepath)

        if File.exists?(filepath)
          entry     = OpenStruct.new({
            :full_filename  => File.basename(relative_filepath),
            :source         => File.new(filepath)
          })
          super(entry)
        else
          # puts "#{filepath} does not exist"
          nil
        end
      end

      protected

      def create_or_update_entry(remote_entry, entry)
        if remote_entry
          merge_entry(remote_entry, entry)

          if self.options[:force]
            OpenStruct.new({
              :success?         => true,
              :parsed_response  => { 'url' => remote_entry.url }
            })
          else
            warning_output(entry)
            nil
          end
        else
          self.create(build_params(entry))
        end
      end

      def label_for(entry)
        File.basename(entry.full_filename)
      end

      def build_params(entry)
        { :source => entry.source }
      end

      def compare_entries(remote_entry, local_entry)
        remote_entry.filename == File.basename(local_entry.full_filename)
      end

    end

  end
end