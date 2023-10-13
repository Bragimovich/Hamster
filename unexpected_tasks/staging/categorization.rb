require_relative 'models/analys_keyword_raw_type'
require_relative 'models/analys_keyword_raw_desc'
require_relative 'models/analys_uniq_categories'
require_relative 'models/staging_cases'
require_relative 'sql/categorization_sql'
require_relative 'tools/message_send'

module UnexpectedTasks
  module Staging
    class Categorization
      def self.run(**options)
        title = 'Staging | Categorization'
        rt_start_count = AnalysKeywordRawType.all.count
        #d_start_count = AnalysUniqCategories.all.count
        raw_type_category
        add_raw_type_category
        #description_category
        #add_description_category
        rt_end_count = AnalysKeywordRawType.all.count
        #d_end_count = AnalysUniqCategories.all.count
        message = "Add `#{rt_end_count - rt_start_count}` new categories from raw types."
        #message += "\nAdd `#{d_end_count - d_start_count}` new categories from descriptions."
        Hamster.logger.info message
        message_send(title, message)
      rescue => e
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        Hamster.logger.error e.full_message
        message_send(title, message)
      end

      def self.raw_type_category
        raw_types = StagingCases.connection.execute(raw_types_from_cases).to_a
        categories = AnalysUniqCategories.all.to_a
        keywords = []
        keywords += categories.map{|item| item['general_category']}.uniq.compact
        keywords += categories.map{|item| item['midlevel_category']}.uniq.compact
        keywords += categories.map{|item| item['specific_category']}.uniq.compact
        keywords += categories.map{|item| item['additional_category']}.uniq.compact
        keywords.delete('Other')
        raw_types.each do |item|
          item = item[0]
          keys = []
          keywords.each do |keyword|
            if item.downcase.include? keyword.downcase
              keys << keyword
            end
          end
          Hamster.logger.info keys.to_s unless keys.blank?
          unless keys.blank?
            keys_categories = []
            keys.each do |key|
              if categories.map{|item| item['additional_category']}.uniq.compact.include? key
                keys_categories << {key: key, category: 4}
              elsif categories.map{|item| item['specific_category']}.uniq.compact.include? key
                keys_categories << {key: key, category: 3}
              elsif categories.map{|item| item['midlevel_category']}.uniq.compact.include? key
                keys_categories << {key: key, category: 2}
              elsif categories.map{|item| item['general_category']}.uniq.compact.include? key
                keys_categories << {key: key, category: 1}
              end
            end
            keys_categories.sort! {|a, b| b[:category] <=> a[:category]}[0]
            case keys_categories[0][:category]
            when 4
              category_id = AnalysUniqCategories.where(additional_category: keys_categories[0][:key]).select(:id).to_a
            when 3
              category_id = AnalysUniqCategories.where(specific_category: keys_categories[0][:key], additional_category: nil).select(:id).to_a
            when 2
              category_id = AnalysUniqCategories.where(midlevel_category: keys_categories[0][:key], additional_category: nil, specific_category: nil).select(:id).to_a
            when 1
              category_id = AnalysUniqCategories.where(general_category: keys_categories[0][:key], additional_category: nil, specific_category: nil, midlevel_category: nil).select(:id).to_a
            end
            category_id = category_id.blank? ? nil : category_id[0][:id]
            unless category_id.blank?
              hash = {
                raw_type: item,
                keyword: keys_categories[0][:key],
                category_id: category_id,
                raw_type_md5: Digest::MD5.hexdigest(item)
              }
              insert_raw_type(hash)
            end
          end
        end
      end

      def self.add_raw_type_category
        raw_types = StagingCases.connection.execute(raw_types_from_cases).to_a
        raw_types.each do |item|
          item = item[0]
          category_id = nil
          if item.include?('dog bite') && item.include?('tort')
            keyword = 'dog bite'
            category_id = 30
          elsif item.include?('lead poisoning') && item.include?('tort')
            keyword = 'lead poisoning'
            category_id = 36
          elsif item.include?('asbestos')
            keyword = 'asbestos'
            category_id = 37
          elsif item.include?('tort')
            keyword = 'tort'
            category_id = 25
          elsif item.include?('real property')
            keyword = 'real property'
            category_id = 18
          elsif item.include?('breach') && item.include?('contract')
            keyword = 'breach'
            category_id = 7
          elsif item.include?('contract')
            keyword = 'contract'
            category_id = 4
          elsif item.include?('lien')
            keyword = 'lien'
            category_id = 9
          elsif item.include?('discrimination')
            keyword = 'discrimination'
            category_id = 2
          elsif item.include?('civil right')
            keyword = 'civil right'
            category_id = 2
          end
          unless category_id.blank?
            hash = {
              raw_type: item,
              keyword: keyword,
              category_id: category_id,
              raw_type_md5: Digest::MD5.hexdigest(item)
            }
            insert_raw_type(hash)
          end
        end
      end

      def self.insert_raw_type(hash)
        check = AnalysKeywordRawType.where("raw_type_md5 = '#{hash[:raw_type_md5]}'").to_a
        if check.blank?
          AnalysKeywordRawType.insert(hash)
          puts "[#{hash[:raw_type]}] ADD IN DATABASE!".green
        else
          puts "[#{hash[:raw_type]}] ALREADY IN DATABASE!".yellow
        end
      end

      def self.keywords_from_categories

        keywords
      end

      def self.description_category
        descriptions = StagingCases.connection.execute(descriptions_from_cases).to_a
        categories = AnalysUniqCategories.all.to_a
        keywords = []
        keywords += categories.map{|item| item['general_category']}.uniq.compact
        keywords += categories.map{|item| item['midlevel_category']}.uniq.compact
        keywords += categories.map{|item| item['specific_category']}.uniq.compact
        keywords += categories.map{|item| item['additional_category']}.uniq.compact
        keywords.delete('Other')
        descriptions.each do |item|
          item = item[0]
          keys = []
          keywords.each do |keyword|
            if item.downcase.include? keyword.downcase
              keys << keyword
            end
          end
          Hamster.logger.info keys.to_s unless keys.blank?
          unless keys.blank?
            keys_categories = []
            keys.each do |key|
              if categories.map{|item| item['additional_category']}.uniq.compact.include? key
                keys_categories << {key: key, category: 4}
              elsif categories.map{|item| item['specific_category']}.uniq.compact.include? key
                keys_categories << {key: key, category: 3}
              elsif categories.map{|item| item['midlevel_category']}.uniq.compact.include? key
                keys_categories << {key: key, category: 2}
              elsif categories.map{|item| item['general_category']}.uniq.compact.include? key
                keys_categories << {key: key, category: 1}
              end
            end
            keys_categories.sort! {|a, b| b[:category] <=> a[:category]}[0]
            case keys_categories[0][:category]
            when 4
              category_id = AnalysUniqCategories.where(additional_category: keys_categories[0][:key]).select(:id).to_a
            when 3
              category_id = AnalysUniqCategories.where(specific_category: keys_categories[0][:key], additional_category: nil).select(:id).to_a
            when 2
              category_id = AnalysUniqCategories.where(midlevel_category: keys_categories[0][:key], additional_category: nil, specific_category: nil).select(:id).to_a
            when 1
              category_id = AnalysUniqCategories.where(general_category: keys_categories[0][:key], additional_category: nil, specific_category: nil, midlevel_category: nil).select(:id).to_a
            end
            category_id = category_id.blank? ? nil : category_id[0][:id]
            unless category_id.blank?
              hash = {
                description: item,
                keyword: keys_categories[0][:key],
                category_id: category_id,
                description_md5: Digest::MD5.hexdigest(item)
              }
              insert_description(hash)
            end
          end
        end
      end

      def self.add_description_category
        descriptions = StagingCases.connection.execute(descriptions_from_cases).to_a
        descriptions.each do |item|
          item = item[0]
          category_id = nil
          if item.include?('dog bite') && item.include?('tort')
            keyword = 'dog bite'
            category_id = 30
          elsif item.include?('lead poisoning') && item.include?('tort')
            keyword = 'lead poisoning'
            category_id = 36
          elsif item.include?('asbestos')
            keyword = 'asbestos'
            category_id = 37
          elsif item.include?('tort')
            keyword = 'tort'
            category_id = 25
          elsif item.include?('real property')
            keyword = 'real property'
            category_id = 18
          elsif item.include?('breach') && item.include?('contract')
            keyword = 'breach'
            category_id = 7
          elsif item.include?('contract')
            keyword = 'contract'
            category_id = 4
          elsif item.include?('lien')
            keyword = 'lien'
            category_id = 9
          elsif item.include?('discrimination')
            keyword = 'discrimination'
            category_id = 2
          elsif item.include?('civil right')
            keyword = 'civil right'
            category_id = 2
          end
          unless category_id.blank?
            hash = {
              description: item,
              keyword: keyword,
              category_id: category_id,
              description_md5: Digest::MD5.hexdigest(item)
            }
            insert_description(hash)
          end
        end
      end

      def self.insert_description(hash)
        check = AnalysKeywordRawType.where("description_md5 = '#{hash[:description_md5]}'").to_a
        if check.blank?
          AnalysKeywordRawType.insert(hash)
          Hamster.logger.info "[#{hash[:description]}] ADD IN DATABASE!".green
        else
          Hamster.logger.info "[#{hash[:description]}] ALREADY IN DATABASE!".yellow
        end
      end
    end
  end
end