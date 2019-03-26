module Tolk
  module Utils
    module_function

    def flat_hash(data, prefix = '', result = {})
      data.each do |key, value|
        current_prefix = prefix.present? ? "#{prefix}.#{key}" : key

        if !value.is_a?(Hash) || Tolk::Locale.pluralization_data?(value)
          result[current_prefix] = value.respond_to?(:stringify_keys) ? value.stringify_keys : value
        else
          flat_hash(value, current_prefix, result)
        end
      end

      result.stringify_keys
    end

    def filter_out_i18n_keys(flat_hash)
      flat_hash.reject { |key, value| key.starts_with? 'i18n' }
    end

    def filter_out_ignored_keys(flat_hash)
      ignored = Tolk.config.ignore_keys

      return flat_hash unless ignored.any?

      ignored_escaped = ignored.map { |key| Regexp.escape(key) }

      regexp = Regexp.new(/\A#{ignored_escaped.join('|')}/)

      flat_hash.reject { |key, _| regexp === key }
    end
  end
end
