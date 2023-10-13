# frozen_string_literal: true

require_relative 'case_types/us_case_types_IRL_model'
require_relative 'us_case_table_analysis/us_court_tables'
require_relative 'pdf_text/pdf_models'

module UnexpectedTasks
  module UsCourts
    class CategorizationAll
      def self.run(**options)
        @keywords = self.keywords(TRUE)
        @limit = options[:limit] || 1000
        final_case_to_category = CaseToCategory.new(**options) if options[:final]
        return if !final_case_to_category.nil?
        Hamster.logger.debug "\nCategorization:"

        type_list = %w[activity activity_saac
                       info_description info_description_saac
                       info_name info_name_saac
                       info_type info_type_saac
                       pdf_saac pdf]
        type_original = %w[activity info_description info_name info_type pdf]
        type_saac = %w[activity_saac info_description_saac info_name_saac info_type_saac pdf_saac]
        type_low = %w[info_description info_description_saac info_name info_name_saac
                      info_type info_type_saac activity activity_saac]
        if options[:type]==nil
          Hamster.logger.info "All"
          type_list.each do |type|
            self.start_new(type)
          end
        elsif options[:type]=='original'
          Hamster.logger.info "Original"
          type_original.each do |type|
            self.start_new(type)
          end
        elsif options[:type]=='saac'
          Hamster.logger.info "SAAC"
          type_saac.each do |type|
            self.start_new(type)
          end
        elsif options[:type]=='low'
          Hamster.logger.info "Low resources are required"
          type_low.each do |type|
            self.start_new(type)
          end
        elsif type_list.include?(options[:type])
          self.start_new(options[:type])
        else
          "We don't this type"
        end
      end

      def self.start_new(type='pdf')
        Hamster.logger.debug "Starting new '#{type}' categorization. Keywords:"
        @keywords.each do |keyword|
          Hamster.logger.debug keyword
          page = 0
          loop do
            offset = @limit*page
            cases =
              case type
              when 'pdf'
                UsCaseReportText.where.not(text_pdf:nil).where('case_id not in (SELECT case_id FROM litigation_keyword_to_case)')
                                .where("text_pdf rlike '#{keyword.gsub("\'","\\'")}'").limit(@limit).offset(offset)
              when 'pdf_saac'
                UsSAACCaseReportText.where.not(text_pdf:nil).where('case_id not in (SELECT case_id FROM litigation_keyword_to_case)')
                                .where("text_pdf rlike '#{keyword.gsub("\'","\\'")}'").limit(@limit).offset(offset)
              when 'activity'
                UsCaseActivities.where.not(activity_decs:nil).where('case_id not in (SELECT case_id FROM us_courts_analysis.litigation_keyword_to_case)')
                                .where("activity_decs rlike '#{keyword}'").limit(@limit).offset(offset)
              when 'activity_saac'
                UsSAACCaseActivities.where.not(activity_desc:nil).where('case_id not in (SELECT case_id FROM us_courts_analysis.litigation_keyword_to_case)')
                                    .where("activity_desc rlike '#{keyword}'").limit(@limit).offset(offset)
              when 'info_description'
                UsCaseInfo.where.not(case_description:nil).where('case_id not in (SELECT case_id FROM us_courts_analysis.litigation_keyword_to_case)')
                          .where("case_description rlike '#{keyword.gsub("\'","\\'")}'").limit(@limit).offset(offset)
              when 'info_description_saac'
                UsSAACCaseInfo.where.not(case_description:nil).where('case_id not in (SELECT case_id FROM us_courts_analysis.litigation_keyword_to_case)')
                          .where("case_description rlike '#{keyword.gsub("\'","\\'")}'").limit(@limit).offset(offset)
              when 'info_name'
                UsCaseInfo.where.not(case_name:nil).where('case_id not in (SELECT case_id FROM us_courts_analysis.litigation_keyword_to_case)')
                          .where("case_name rlike '#{keyword.gsub("\'","\\'")}'").limit(@limit).offset(offset)
              when 'info_name_saac'
                UsSAACCaseInfo.where.not(case_name:nil).where('case_id not in (SELECT case_id FROM us_courts_analysis.litigation_keyword_to_case)')
                          .where("case_name rlike '#{keyword.gsub("\'","\\'")}'").limit(@limit).offset(offset)
              when 'info_type'
                UsCaseInfo.where.not(case_type:nil).where('case_id not in (SELECT case_id FROM us_courts_analysis.litigation_keyword_to_case)')
                          .where("case_type rlike '#{keyword.gsub("\'","\\'")}'").limit(@limit).offset(offset)
              when 'info_type_saac'
                UsSAACCaseInfo.where.not(case_type:nil).where('case_id not in (SELECT case_id FROM us_courts_analysis.litigation_keyword_to_case)')
                          .where("case_type rlike '#{keyword.gsub("\'","\\'")}'").limit(@limit).offset(offset)
              end


            cases.each do |the_case|
              pdf_link= nil

              if type=='pdf'
                pdf_link = the_case.aws_link
                pdf_link = pdf_link.gsub(' ', '%20') if !pdf_link.nil?
              end
              
              kw_to_db = {
                keyword: keyword,
                court_id: the_case.court_id,
                case_id: the_case.case_id,
                type: type,
                pdf_link: pdf_link,
              }
              #kw_to_db = get_keywords(keywords_hash, case_text.id, pdf_link)
              LitigationKeywordToCase.insert(kw_to_db) #if !kw_to_db.empty?

            end
            page+=1
            break page if cases.to_a.length<@limit
          end
          LitigationKeywordToCase.connection.reconnect!
        end

      end

      def self.keywords(opt)
        if opt==TRUE
          keywords = LitigationCaseTypeIRLKeywords.all().select(:keyword).distinct.map { |row| row.keyword }
          keywords += UsCaseTypesIRLCategorized.where.not(midlevel_category:nil).select(:midlevel_category).distinct.map { |row| row.midlevel_category  }
          keywords += UsCaseTypesIRLCategorized.where.not(specific_category:nil).select(:specific_category).distinct.map { |row| row.specific_category  }
          keywords += UsCaseTypesIRLCategorized.where.not(additional_category:nil).select(:additional_category).distinct.map { |row| row.additional_category  }
          keywords += UsCaseTypesIRLCategorized.where.not(general_category:nil).select(:general_category).distinct.map { |row| row.general_category  }
        else
          keywords = UsCaseTypesIRLCategorized.where.not(midlevel_category:nil).select(:midlevel_category).distinct.map { |row| row.midlevel_category  }
          keywords += UsCaseTypesIRLCategorized.where.not(specific_category:nil).select(:specific_category).distinct.map { |row| row.specific_category  }
          keywords += UsCaseTypesIRLCategorized.where.not(additional_category:nil).select(:additional_category).distinct.map { |row| row.additional_category  }
          keywords += LitigationCaseTypeIRLKeywords.all().select(:keyword).distinct.map { |row| row.keyword }
          keywords += UsCaseTypesIRLCategorized.where.not(general_category:nil).select(:general_category).distinct.map { |row| row.general_category  }
        end
        keywords
      end

    end


    class CaseToCategory

      def initialize(**options)
        Hamster.logger.debug 'case to category'
        @categories_unique = categories_unique
        @keywords_to_categories = keywords_to_categories
        start(**options)
      end

      def start(options)
        page = 0
        limit = options[:limit] || 100
        loop do
          Hamster.logger.debug "page #{page}"
          offset = page * limit
          keyword_to_cases =
          if !options[:update].nil?
            LitigationKeywordToCase.where('case_id not in (SELECT case_id FROM us_courts_analysis.litigation_case_to_unique_category)').limit(limit).offset(offset)
          else
            LitigationKeywordToCase.limit(limit).offset(offset)
          end

          keyword_to_cases.each do |keyword_case|
            put_in_db = []
            category_name = @keywords_to_categories[keyword_case.keyword]
            category_name = keyword_case.keyword if category_name.nil?

            @categories_unique.each do |cat_unique|
              [:additional_category, :specific_category, :midlevel_category, :general_category].each do |category_keyword|
                keyword_in_category = cat_unique[category_keyword]
                #p keyword_in_category
                if !keyword_in_category.nil? and keyword_in_category==category_name
                    put_in_db.push({
                                     :court_id => keyword_case.court_id,
                                     :case_id => keyword_case.case_id,
                                     :pdf_link => keyword_case.pdf_link,
                                     :unique_category_id => cat_unique[:unique_category_id]
                                   })
                end
              end
            end
            LitigationCaseToUniqueCategory.insert_all(put_in_db) if !put_in_db.empty?
          end
          page = page + 1
          break if keyword_to_cases.to_a.length<limit

        end

      end

      def categories_unique
        categories = []
        LitigationCaseTypeIRLUniqueCategories.all().each do |row|
          categories.push({
                            :unique_category_id => row.id,
                            :general_category => row.general_category,
                            :midlevel_category => row.midlevel_category,
                            :specific_category => row.specific_category,
                            :additional_category => row.additional_category,
                          })
        end
        categories
      end

      def keywords_to_categories
        keywords_to_cat = {}
        LitigationCaseTypeIRLKeywords.all().map { |row| keywords_to_cat[row.keyword] = row.category_name }
        keywords_to_cat
      end


    end

  end
end