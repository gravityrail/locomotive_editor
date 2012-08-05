module LocomotiveEditor
  module Api

    class Page < Base

      attr_accessor :content_assets_service, :content_types_service

      def list
        self.class.get('/pages.json')
      end

      def create(params = {})
        self.class.post(
          '/pages.json',
          :body => { :page => params }
        )
      end

      def update(id, params = {}, extra_params = {})
        self.class.put(
          "/pages/#{id}.json",
          :body => { :page => params }.merge(extra_params)
        )
      end

      def push(entries)
        @entries, @done_entries = entries.clone, []

        assign_ids_to_entries

        super(entries)
      end

      def push_entry(entry)
        return entry if already_processed?(entry)

        parent_path = entry.parent_path
        parent = @entries.detect { |_entry| _entry.fullpath == parent_path }

        entry.parent_id = parent._id if parent

        create_or_update(entry)
      end

      def push_translated_entry(entry, value, locale)
        page = Models::Page.new({
          :title        => entry.title,
          :fullpath     => entry.fullpath,
          :site         => OpenStruct.new(:default_locale => ''),
          :translations => { locale => value }
        })

        response = self.update(entry._id, {
            :title        => page.title(locale),
            :raw_template => page.raw_template(locale),
            :slug         => File.basename(page.fullpath(locale))
          }, { :locale => locale })

        output entry, response, false, locale
      end

      protected

      def push_entry_folder(fullpath)
         LocomotiveEditor::Models::Page.new({
           :site      => LocomotiveEditor::Models::Site.first,
           :fullpath  => fullpath,
           :listed    => false,
           :published => false
          }).tap do |entry|
           @entries << entry
           create_or_update(entry)
         end
       end

      def create_or_update(entry)
        translations = entry.translations || {}

        entry.delete_field('translations') rescue nil

        if persisted = entry.persisted?
          if self.options[:force]
            response = self.update(entry._id, build_params(entry))
          else
            response = nil
            warning_output(entry)
          end
        else
          response = self.create(build_params(entry))
          entry._id = response.parsed_response['_id'] if response.success?
        end

        @done_entries << entry._id # mark it as done

        unless response.nil?
          output entry, response, !persisted

          translations.each_pair do |locale, value|
            entry._id = response.parsed_response['_id']
            self.push_translated_entry(entry, value, locale)
          end if response.success?
        end

        entry
      end

      def build_params(entry)
        push_content_assets(entry)

        assign_content_type(entry) if entry.templatized?

        entry.to_hash
      end

      def label_for(entry)
        "#{entry.title} (#{entry.fullpath})"
      end

      def compare_entries(remote_entry, local_entry)
        remote_entry.fullpath == local_entry.fullpath
      end

      def assign_ids_to_entries
        @entries.each do |entry|
          _remote_entry = find_existing_entry(entry)

          if _remote_entry
            entry._id = _remote_entry._id
          end
        end
      end

      def already_processed?(entry)
        @done_entries.include?(entry._id)
      end

      def push_content_assets(entry)
        (entry.raw_template || '').gsub!(/\/samples\/.*\.[a-zA-Z0-9]+/) do |match|
          asset = self.content_assets_service.push_entry match
          asset ? asset.parsed_response['url'] : match
        end
      end

      def assign_content_type(entry)
        if entry.content_type && content_type = self.content_types_service.find_existing_entry(entry.content_type)
          entry.target_klass_name = content_type.klass_name
        else
          entry.target_klass_name = entry.model
        end
      end

    end

  end
end