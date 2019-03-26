module Tolk
  module Import
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def import_secondary_locales
        locales = Tolk::Locale.where.not(name: Tolk::Locale.primary_locale.name).pluck(:name)

        # locales = Dir.entries(self.locales_config_path)
        #
        # locale_block_filter = Proc.new {
        #   |l| ['.', '..'].include?(l) ||
        #     !l.ends_with?('.yml') ||
        #     l.match(/(.*\.){2,}/) # reject files of type xxx.en.yml
        # }
        # locales = locales.reject(&locale_block_filter).map {|x| x.split('.').first }
        # locales = locales - [Tolk::Locale.primary_locale.name]
        locales.each { |l| import_locale(l) }
      end

      def import_locale(locale_name)
        locale = Tolk::Locale.where(name: locale_name).first_or_create
        data = locale.read_locale_file
        return unless data

        phrases_by_key = Tolk::Phrase.all.index_by(&:key)
        translated_phrase_ids = Set.new(locale.translations.pluck(:phrase_id))
        count = 0

        data.each do |key, value|
          phrase = phrases_by_key[key]

          unless phrase
            puts "[ERROR] Key '#{key}' was found in '#{locale_name}.yml' but #{Tolk::Locale.primary_language_name} translation is missing"
            next
          end

          if translated_phrase_ids.include?(phrase.id)
            next if value.to_s.empty?

            translation = locale.translations.find_by(:phrase_id => phrase.id)
            translation.text = value

            next unless translation.changed?
          else
            translation = locale.translations.new(:text => value, :phrase => phrase)
          end

          if translation.save
            count = count + 1
          elsif translation.errors[:variables].present?
            puts "[WARN] Key '#{key}' from '#{locale_name}.yml' could not be saved: #{translation.errors[:variables].first}"
          end
        end

        puts "[INFO] Imported #{count} keys from #{locale_name}.yml"
      end
    end

    def read_locale_file
      I18n.backend.init_translations unless I18n.backend.initialized?
      translations = Tolk::Utils.flat_hash(I18n.backend.translations[self.name.to_sym])
      translations = Tolk::Utils.filter_out_i18n_keys(translations)
      Tolk::Utils.filter_out_ignored_keys(translations)
    end
  end
end
