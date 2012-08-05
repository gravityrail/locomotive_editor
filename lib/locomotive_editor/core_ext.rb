require 'active_support/inflector'
require 'active_support/core_ext/string'

class Hash

  def underscore_keys
    new_hash = {}

    self.each_pair do |key, value|
      if value.respond_to?(:collect!) # Array
        value.collect do |item|
          if item.respond_to?(:each_pair) # Hash item within
            item.underscore_keys
          else
            item
          end
        end
      elsif value.respond_to?(:each_pair) # Hash
        value = value.underscore_keys
      end

      new_key = key.is_a?(String) ? key.underscore : key # only String keys

      new_hash[new_key] = value
    end

    self.replace(new_hash)
  end

  def stringify_keys!
    keys.each do |key|
      value = delete(key)

      if value.respond_to?(:stringify_keys!)
        value.stringify_keys!
      end

      self[key.to_s] = value
    end
    self
  end

  def deep_stringify_keys
    new_hash = {}
    self.each do |key, value|
      new_hash.merge!(key.to_s => (value.is_a?(Hash) ? value.deep_stringify_keys : value))
    end
  end

end

class String

  def permalink
    self.parameterize('-')
  end

  def permalink!
    replace(self.permalink)
  end

  alias :parameterize! :permalink!

  alias :slugify :permalink

end

require 'will_paginate/collection'

Array.class_eval do
  def paginate(options = {})
    raise ArgumentError, "parameter hash expected (got #{options.inspect})" unless Hash === options

    WillPaginate::Collection.create(
        options[:page] || 1,
        options[:per_page] || 30,
        options[:total_entries] || self.length
    ) { |pager|
      pager.replace self[pager.offset, pager.per_page].to_a
    }
  end
end