module LocomotiveEditor
  module Api

    module Helpers

      extend ActiveSupport::Concern

      included do

        attr_accessor :auth_token, :options, :all_entries

      end

      def push(entries)
        entries.each do |entry|
          push_entry(entry)
        end
      end

      def push_entry(entry)
        remote_entry = find_existing_entry(entry)

        translations = entry.translations rescue {}
        entry.delete_field('translations') rescue nil

        response = create_or_update_entry(remote_entry, entry)

        return nil if response.nil?

        output entry, response, remote_entry.nil?

        if response.success?
          self.update_entry_with_response(entry, response)

          (self.all_entries ||= []) << entry

          (translations || {}).each_pair do |locale, value|
            self.push_translated_entry(entry, value, locale)
          end

          response
        else
          nil
        end
      end

      def push_translated_entry(entry, locale)
        #  TO BE OVERRIDDEN
      end

      protected

      def create_or_update_entry(remote_entry, entry)
        if remote_entry
          merge_entry(remote_entry, entry)

          if self.options[:force]
            self.update(remote_entry._id, build_params(entry))
          else
            warning_output(entry)
            nil
          end
        else
          self.create(build_params(entry))
        end
      end

      def output(entry, response, new_entry, locale = nil)
        locale = locale ? "(#{locale})" : ''
        if response.success?
          puts "\t[#{self.class.name.demodulize}]... sending #{label_for(entry)} #{locale} " + "#{new_entry ? 'Created' : 'Updated'}".colorize(:color => :green)
        else
          puts "\t[#{self.class.name.demodulize}]... sending #{label_for(entry)} #{locale} " + "Failed (#{response.code})".colorize(:color => :white, :background => :red)
          # puts response.inspect
          if response.parsed_response.respond_to?(:keys)
            response.parsed_response.each do |attribute, errors|
              puts "\t\t #{attribute} => #{[*errors].join(', ')}"
            end
          end
        end
      end

      def warning_output(entry)
         puts "\t[#{self.class.name.demodulize}]... sending #{label_for(entry)}  " + "Skipped".colorize(:color => :blue)
      end

      def label_for(entry)
        raise 'the entry_label method in Api::Base must be overidden'
      end

      def remote_entries
        @remote_entries ||= list
      end

      def update_entry_with_response(entry, response)
        entry._id = response.parsed_response['_id']
      end

      def merge_entry(remote_entry, local_entry)
        # only when updating an entry
        # not needed by default
      end

      def build_params(entry)
        entry.marshal_dump
      end

      def find_existing_entry(entry)
        record = remote_entries.detect do |_record|
          compare_entries(OpenStruct.new(_record), entry)
        end

        if record
          OpenStruct.new(record.merge!(:_id => record['id']))
        else
          nil
        end
      end

      def compare_entries(remote_entry, local_entry)
        raise 'the compare_entries method in Api::Base must be overidden'
      end

      module ClassMethods

        def push(token, entries, options = {})
          new(token, options).push(entries)
        end

      end

    end

  end
end