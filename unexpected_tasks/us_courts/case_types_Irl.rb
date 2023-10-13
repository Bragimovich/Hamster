# frozen_string_literal: true

require_relative 'case_types/us_case_types_IRL_model'
require_relative 'us_case_table_analysis/us_court_tables'
require_relative 'pdf_text/pdf_models'

module UnexpectedTasks
  module UsCourts
    class CaseTypesIrl
      def self.run(**options)
        self.count_tables if options[:count]
        TextResearch.new(**options) if options[:text]
        UniqueKeywords.new(**options) if options[:keyword]
        UniqueKeywordsNew.new(**options) if options[:keyword_new]
        MatchingKeyword.new(**options) if options[:matchkey]
        PdfCategories.new(**options) if options[:pdfs]
        ActivitiesAnalysis.new(**options) if options[:activities]

        #New matching for info pdf
        PdfCategoriesNew.new(**options) if options[:pdfs_new]

        KeywordToDescription.new(**options) if options[:case_desc]
        DescriptionCategories.new(**options) if options[:match_desc]


        if options[:true_keyword]
          UniqueKeywordsNew.new(**options)
          MatchingKeyword.new(**options)
        end

      end

      def self.count_tables
        p 'Count in categorized IRL table'
        UsCaseTypesIRLCategorized.where.not(court_id:nil).each do |row|
          p row.case_type
          if !row.general_category.nil?
            row.count_general = row.count
          end

          if !row.midlevel_category.nil?
            row.count_midlevel = row.count
            row.midlevel_category = row.midlevel_category.split(' - ')[-1]
          end

          if !row.specific_category.nil?
            row.count_specific = row.count
            row.specific_category = row.specific_category.split(' - ')[-1]
          end

          if !row.additional_category.nil?
            row.count_additional = row.count
            row.additional_category = row.additional_category.split(' - ')[-1]
          end
          row.save
        end

      end

    end

    class TextResearch

      #KEYWORDS = ['Professional/Disciplinary', 'Contract', 'Real Property', 'Torts', 'Forfeiture/Penalty', 'Labor', 'Debt Collection/Liens', 'Other Statutes', 'Civil Rights', 'Foreclosure', 'Personal Injury', 'Personal Property', 'Rent Lease & Ejectment', "Workers' Compensation", 'Commercial', 'Insurance', 'Consumer Credit', 'Non-commercial', 'All Other Real Property', 'Arbitration', 'Other Contract', 'Employment', 'Breach', 'Medical Malpractice', 'Asbestos Personal Injury Product Liability', 'Redemption', 'Product Liability', 'Motor Vehicle', 'Tax Certiorari', 'Commercial Mortgage', 'Partition', 'Quiet Title', 'Assault, Libel, & Slander', 'Conversion', 'Dog Bite', 'Premises', 'Other Fraud', 'Nursing Home', 'Other Personal Injury', 'Property Damage Product Liability', '"Negligent Hiring, Supervision, or Retention"', 'Wrongful Death', 'Legal Malpractice', 'False Arrest or Imprisonment', 'Lead Paint', 'Slip & Fall', 'Subrogation']

      def initialize(**options)
        @limit = options[:limit] ? options[:limit] : 100
        start_time = Time.now().to_i
        @keywords = keywords.uniq #| KEYWORDS
        all_rows = matching_words*@limit
        end_time = Time.now().to_i
        puts "Time for finish #{all_rows} rows: #{end_time-start_time} seconds"
      end

      def matching_words
        p 'Matching words in table'
        page = 0

        loop do
          offset = @limit*page
          cases = CaseReportAwsText.where.not(text_pdf:nil).limit(@limit).offset(offset)
          cases.each do |row|

            keywords_hash = how_many_words(row.text_pdf)
            keywords_hash = how_many_words(row.text_ocr) if keywords_hash.empty? and !row.text_ocr.nil?

            keywords_hash2 = keywords_hash.sort_by { |keyword, count| count }.last(5).reverse

            pdf_link = row.link_pdf
            pdf_link = pdf_link.gsub(' ', '%20') if !pdf_link.nil?

            existing_row = UsCaseReportIRL.where(link_pdf: pdf_link).first
            if existing_row.nil?
              UsCaseReportIRL.insert({
                                            court_id: row.court_id,
                                            case_id: row.case_id,
                                            activity_id: row.activity_id,
                                            top5_matches: keywords_hash2.to_s,
                                            link_pdf: pdf_link
                                          })
            else
              existing_row.update({
                                            court_id: row.court_id,
                                            case_id: row.case_id,
                                            activity_id: row.activity_id,
                                            top5_matches: keywords_hash2.to_s,
                                            link_pdf: pdf_link
                                          })
            end


          end
          page+=1
          return page if cases.to_a.length<@limit
        end

      end

      def how_many_words(text)
        words = {}

        @keywords.each do |keyword|
          next if keyword.in?(words)
          count = text.downcase.scan(keyword.downcase).size
          words[keyword] = count if count>0
        end

        words
      end

      private

      def keywords
        keywords = UsCaseTypesIRLCategorized.where.not(general_category:nil).select(:general_category).distinct.map { |row| row.general_category  }
        keywords += UsCaseTypesIRLCategorized.where.not(midlevel_category:nil).select(:midlevel_category).distinct.map { |row| row.midlevel_category  }
        keywords += UsCaseTypesIRLCategorized.where.not(specific_category:nil).select(:specific_category).distinct.map { |row| row.specific_category  }
        keywords += UsCaseTypesIRLCategorized.where.not(additional_category:nil).select(:additional_category).distinct.map { |row| row.additional_category  }
        keywords
      end


    end

    class UniqueKeywords
      def initialize(**options)
        @limit = options[:limit] ? options[:limit] : 100
        @categories_unique = categories_unique
        @keywords = keywords
        start
      end

      def start
        p 'Matching words in table'
        page = 0

        loop do
          offset = @limit*page
          cases = CaseReportAwsText.where.not(text_pdf:nil).limit(@limit).offset(offset)
          cases.each do |case_text|


            keywords_hash = how_many_words(case_text.text_pdf)
            keywords_hash = how_many_words(case_text.text_ocr) if keywords_hash.empty? and !case_text.text_ocr.nil?

            pdf_link = case_text.link_pdf
            pdf_link = pdf_link.gsub(' ', '%20') if !pdf_link.nil?

            kw_to_db = get_keywords(keywords_hash, case_text.id, pdf_link)
            LitigationCaseTypeIRLKeywordToText.insert_all(kw_to_db) if !kw_to_db.empty?
          end

          page+=1
          return page if cases.to_a.length<@limit
        end

      end

      def get_keywords(keywords_hash, text_id, pdf_link)
        kw_to_db = []
        keywords_hash.each do |keyword, count|
          kw_to_db.push({
                          keyword: keyword,
                          count: count,
                          report_text_id: text_id,
                          pdf_link: pdf_link,
                        })

        end
        kw_to_db
      end

      def how_many_words(text)
        words = {}

        @keywords.each do |keyword|
          next if keyword.in?(words)
          count = text.downcase.scan(keyword.downcase).size
          words[keyword] = count if count>0
        end

        words
      end

      def categories_unique
        categories = {}
        UsCaseTypesIRLCategorized.all().each do |row|
          categories[:general_category]    = row.general_category
          categories[:midlevel_category]   = row.midlevel_category
          categories[:specific_category]   = row.specific_category
          categories[:additional_category] = row.additional_category
        end
      end



      def keywords
        #keywords = LitigationCaseTypeIRLKeywords.all().select(:keyword).distinct.map { |row| row.keyword }
        keywords = UsCaseTypesIRLCategorized.where.not(general_category:nil).select(:general_category).distinct.map { |row| row.general_category  }
        keywords += UsCaseTypesIRLCategorized.where.not(midlevel_category:nil).select(:midlevel_category).distinct.map { |row| row.midlevel_category  }
        keywords += UsCaseTypesIRLCategorized.where.not(specific_category:nil).select(:specific_category).distinct.map { |row| row.specific_category  }
        keywords += UsCaseTypesIRLCategorized.where.not(additional_category:nil).select(:additional_category).distinct.map { |row| row.additional_category  }
        keywords
      end
    end


    class UniqueKeywordsNew
      def initialize(**options)
        @limit = options[:limit] ? options[:limit].to_i : 10
        @categories_unique = categories_unique
        @keywords = keywords(options[:true_keyword])
        @update = options[:update] || 0
        p 'hi'
        start_new
      end

      def start_new # match keyword to pdf info (17/06/22)
        p 'Matching words in table'

        @keywords.each do |keyword|
          p keyword
          page = 0
          loop do
            offset = @limit*page
            p @update
            cases =
              if @update!=0
                UsCaseReportText.where.not(text_pdf:nil).where('case_id not in (SELECT ucrt.case_id FROM us_case_pdfs_keyword_to_text pdf join us_case_report_text ucrt on pdf.case_report_text_id = ucrt.id)')
                                .where("text_pdf rlike '#{keyword.gsub("\'","\\'")}'").limit(@limit).offset(offset)
              else
                UsCaseReportText.where.not(text_pdf:nil).where("text_pdf rlike '#{keyword.gsub("\'","\\'")}'").limit(@limit).offset(offset)
              end
            report_text_ids = cases.map {|row| row.id}
            #existing_report_id = get_existing_case_report_text_id(keyword, report_text_ids)

            cases.each do |case_text|
              #next if case_text.id.in?(existing_report_id)
              #p case_text.id
              #keywords_hash = how_many_words(case_text.text_pdf)
              #keywords_hash = how_many_words(case_text.text_ocr) if keywords_hash.empty? and !case_text.text_ocr.nil?
              #p keywords_hash
              pdf_link = case_text.aws_link
              pdf_link = pdf_link.gsub(' ', '%20') if !pdf_link.nil?
              kw_to_db = {
                keyword: keyword,
                case_report_text_id: case_text.id,
                pdf_link: pdf_link
              }
              #kw_to_db = get_keywords(keywords_hash, case_text.id, pdf_link)
              UsCasePdfsKeywordToText.insert(kw_to_db) #if !kw_to_db.empty?

            end
            page+=1
            break page if cases.to_a.length<@limit
          end
        end

      end

      def get_existing_case_report_text_id(keyword, report_text_ids)
        UsCasePdfsKeywordToText.where(case_report_text_id: report_text_ids).where(keyword:keyword).map {|row| row.case_report_text_id}
      end



      def start_act
        p 'Matching words in table'

        @keywords.each do |keyword|
          p keyword
          page = 0
          loop do
            offset = @limit*page
            cases = CaseReportAwsText.where.not(text_pdf:nil).where("text_pdf rlike '#{keyword}'").limit(@limit).offset(offset) # or text_ocr rlike '#{keyword}'
            report_text_ids = cases.map {|row| row.id}
            existing_report_id = get_existing_report_text_id(keyword, report_text_ids)
            p existing_report_id
              cases.each do |case_text|
                next if case_text.id.in?(existing_report_id)
                #p case_text.id
                #keywords_hash = how_many_words(case_text.text_pdf)
                #keywords_hash = how_many_words(case_text.text_ocr) if keywords_hash.empty? and !case_text.text_ocr.nil?
                #p keywords_hash
                pdf_link = case_text.link_pdf
                pdf_link = pdf_link.gsub(' ', '%20') if !pdf_link.nil?
                kw_to_db = {
                  keyword: keyword,
                  report_text_id: case_text.id,
                  pdf_link: pdf_link
                }
                #kw_to_db = get_keywords(keywords_hash, case_text.id, pdf_link)
                LitigationCaseTypeIRLKeywordToText.insert(kw_to_db) #if !kw_to_db.empty?
              end
            page+=1
            break page if cases.to_a.length<@limit
          end
        end

      end

      def get_existing_report_text_id(keyword, report_text_ids)
        LitigationCaseTypeIRLKeywordToText.where(report_text_id: report_text_ids).where(keyword:keyword).map {|row| row.report_text_id}
      end

      def get_keywords(keywords_hash, text_id, pdf_link)
        kw_to_db = []
        keywords_hash.each do |keyword, count|
          kw_to_db.push({
                          keyword: keyword,
                          count: count,
                          report_text_id: text_id,
                          pdf_link: pdf_link,
                        })

        end
        kw_to_db
      end

      def how_many_words(text)
        words = {}

        @keywords.each do |keyword|
          next if keyword.in?(words)
          count = text.downcase.scan(keyword.downcase).size
          words[keyword] = count if count>0
        end

        words
      end

      def categories_unique
        categories = {}
        UsCaseTypesIRLCategorized.all().each do |row|
          categories[:general_category]    = row.general_category
          categories[:midlevel_category]   = row.midlevel_category
          categories[:specific_category]   = row.specific_category
          categories[:additional_category] = row.additional_category
        end
      end



      def keywords(opt)
        if opt==TRUE
          p 'hi45'
          keywords = LitigationCaseTypeIRLKeywords.all().select(:keyword).distinct.map { |row| row.keyword }
          keywords += UsCaseTypesIRLCategorized.where.not(midlevel_category:nil).select(:midlevel_category).distinct.map { |row| row.midlevel_category  }
          keywords += UsCaseTypesIRLCategorized.where.not(specific_category:nil).select(:specific_category).distinct.map { |row| row.specific_category  }
          keywords += UsCaseTypesIRLCategorized.where.not(additional_category:nil).select(:additional_category).distinct.map { |row| row.additional_category  }
        else
          #keywords = UsCaseTypesIRLCategorized.where.not(general_category:nil).select(:general_category).distinct.map { |row| row.general_category  }
          keywords = UsCaseTypesIRLCategorized.where.not(midlevel_category:nil).select(:midlevel_category).distinct.map { |row| row.midlevel_category  }
          keywords += UsCaseTypesIRLCategorized.where.not(specific_category:nil).select(:specific_category).distinct.map { |row| row.specific_category  }
          keywords += UsCaseTypesIRLCategorized.where.not(additional_category:nil).select(:additional_category).distinct.map { |row| row.additional_category  }
          keywords += LitigationCaseTypeIRLKeywords.all().select(:keyword).distinct.map { |row| row.keyword }
        end
        keywords
      end
    end


    class PdfCategoriesNew

      def initialize(**options)
        @categories_unique = categories_unique
        @update = options[:update] || 0
        p 'START PDF CATEGORIZING'
        start
      end

      def start
        texts_id =
          if @update!=0
            UsCasePdfsKeywordToText.where("case_report_text_id not in (SELECT case_report_text_id FROM us_case_pdfs_unique_categories)")
          else
            UsCasePdfsKeywordToText.all()
          end

        texts_id.group(:case_report_text_id).each do |text_id|
          put_in_db = []
          keywords = UsCasePdfsKeywordToText.where(case_report_text_id:text_id.case_report_text_id).map {|row| row[:keyword]}
          @categories_unique.each do |cat_unique|
            [:additional_category, :specific_category, :midlevel_category, :general_category].each do |category_keyword|
              keyword_in_category = cat_unique[category_keyword]
              if !keyword_in_category.nil?
                break if !keyword_in_category.in?(keywords)
                #p "#{category_keyword}: #{keyword_in_category}"
                if category_keyword==:general_category
                  put_in_db.push({
                                   :case_report_text_id => text_id.case_report_text_id,
                                   :pdf_link => text_id.pdf_link,
                                   :unique_category_id => cat_unique[:unique_category_id]
                                   # :general_category => cat_unique[:general_category],
                                   # :midlevel_category => cat_unique[:midlevel_category],
                                   # :specific_category => cat_unique[:specific_category],
                                   # :additional_category => cat_unique[:additional_category],
                                 })
                end
              end
            end
          end
          p put_in_db
          UsCasePdfsUniqueCategories.insert_all(put_in_db) if !put_in_db.empty?
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


    end


    class DescriptionCategories

      def initialize(**options)
        @categories_unique = categories_unique
        p 'hi'
        start
      end

      def start
        page = 0
        limit = 1000
        loop do
          offset = page*limit
          cases = UsCaseKeywordToDescription.all().group(:case_id).limit(limit).offset(offset)
          cases.each do |text_id|
            put_in_db = []
            keywords = UsCaseKeywordToDescription.where(case_id:text_id.case_id).map {|row| row[:keyword]}
            @categories_unique.each do |cat_unique|
              [:additional_category, :specific_category, :midlevel_category, :general_category].each do |category_keyword|
                keyword_in_category = cat_unique[category_keyword]
                if !keyword_in_category.nil?
                  break if !keyword_in_category.in?(keywords)
                  #p "#{category_keyword}: #{keyword_in_category}"
                  if category_keyword==:general_category
                    put_in_db.push({
                                     :case_id => text_id.case_id,
                                     :court_id => text_id.court_id,
                                     :unique_category_id => cat_unique[:unique_category_id]
                                     # :general_category => cat_unique[:general_category],
                                     # :midlevel_category => cat_unique[:midlevel_category],
                                     # :specific_category => cat_unique[:specific_category],
                                     # :additional_category => cat_unique[:additional_category],
                                   })
                  end
                end
              end
            end
            p put_in_db
            UsCaseKeywordUniqueCategories.insert_all(put_in_db) if !put_in_db.empty?
            page = page+1
            break if cases.to_a.length<limit
          end
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


    end

    class KeywordToDescription
      def initialize(**options)
        @limit = options[:limit] ? options[:limit].to_i : 100
        @keywords = keywords()
        start_new
      end

      def start_new # match keyword to pdf info (17/06/22)
        p 'Matching words in desciption'

        @keywords.each do |keyword|
          p keyword
          page = 0
          loop do
            offset = @limit*page
            cases = UsCaseInfo.where.not(case_description:nil).where("case_description rlike '#{keyword.gsub("\'","\\'")}'").limit(@limit).offset(offset)
            case_ids = cases.map {|row| row.case_id}
            existing_case_id = get_existing_case_id_keyword(keyword, case_ids)
            #p existing_report_id
            cases.each do |case_text|
              next if existing_case_id.include?(case_text.case_id)
              #p case_text.id
              #keywords_hash = how_many_words(case_text.text_pdf)
              #keywords_hash = how_many_words(case_text.text_ocr) if keywords_hash.empty? and !case_text.text_ocr.nil?
              #p keywords_hash

              kw_to_db = {
                keyword: keyword,
                court_id: case_text.court_id,
                case_id: case_text.case_id,
                case_text: case_text.case_description,
                type_categorization: 'case_description',
              }
              #kw_to_db = get_keywords(keywords_hash, case_text.id, pdf_link)
              UsCaseKeywordToDescription.insert(kw_to_db) #if !kw_to_db.empty?
            end
            page+=1
            break page if cases.to_a.length<@limit
          end
        end

      end

      def get_existing_case_id_keyword(keyword, case_ids)
        UsCaseKeywordToDescription.where(case_id: case_ids).where(keyword:keyword).map {|row| row.case_id}
      end


      def keywords
        # keywords = LitigationCaseTypeIRLKeywords.all().select(:keyword).distinct.map { |row| row.keyword }
        keywords = UsCaseTypesIRLCategorized.where.not(general_category:nil).select(:general_category).distinct.map { |row| row.general_category  }
        keywords += UsCaseTypesIRLCategorized.where.not(midlevel_category:nil).select(:midlevel_category).distinct.map { |row| row.midlevel_category  }
        keywords += UsCaseTypesIRLCategorized.where.not(specific_category:nil).select(:specific_category).distinct.map { |row| row.specific_category  }
        keywords += UsCaseTypesIRLCategorized.where.not(additional_category:nil).select(:additional_category).distinct.map { |row| row.additional_category  }
        keywords
      end

    end

    class PdfCategories

      def initialize(**options)
        @categories_unique = categories_unique
        start
      end

      def start

        LitigationCaseTypeIRLKeywordToText.all().group(:report_text_id).each do |text_id|
          put_in_db = []
          keywords = LitigationCaseTypeIRLKeywordToText.where(report_text_id:text_id.report_text_id).map {|row| row[:keyword]}
          @categories_unique.each do |cat_unique|
            [:additional_category, :specific_category, :midlevel_category, :general_category].each do |category_keyword|
              keyword_in_category = cat_unique[category_keyword]
              if !keyword_in_category.nil?
                break if !keyword_in_category.in?(keywords)
                #p "#{category_keyword}: #{keyword_in_category}"
                if category_keyword==:general_category
                  put_in_db.push({
                                   :report_text_id => text_id.report_text_id,
                                   :pdf_link => text_id.pdf_link,
                                   :unique_category_id => cat_unique[:unique_category_id]
                                   # :general_category => cat_unique[:general_category],
                                   # :midlevel_category => cat_unique[:midlevel_category],
                                   # :specific_category => cat_unique[:specific_category],
                                   # :additional_category => cat_unique[:additional_category],
                                 })
                end
              end
            end
          end
          #p put_in_db
          LitigationCaseTypeIRLPdfsUniqueCategories.insert_all(put_in_db) if !put_in_db.empty?
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


    end

    class MatchingKeyword

      #KEYWORDS = ['Professional/Disciplinary', 'Contract', 'Real Property', 'Torts', 'Forfeiture/Penalty', 'Labor', 'Debt Collection/Liens', 'Other Statutes', 'Civil Rights', 'Foreclosure', 'Personal Injury', 'Personal Property', 'Rent Lease & Ejectment', "Workers' Compensation", 'Commercial', 'Insurance', 'Consumer Credit', 'Non-commercial', 'All Other Real Property', 'Arbitration', 'Other Contract', 'Employment', 'Breach', 'Medical Malpractice', 'Asbestos Personal Injury Product Liability', 'Redemption', 'Product Liability', 'Motor Vehicle', 'Tax Certiorari', 'Commercial Mortgage', 'Partition', 'Quiet Title', 'Assault, Libel, & Slander', 'Conversion', 'Dog Bite', 'Premises', 'Other Fraud', 'Nursing Home', 'Other Personal Injury', 'Property Damage Product Liability', '"Negligent Hiring, Supervision, or Retention"', 'Wrongful Death', 'Legal Malpractice', 'False Arrest or Imprisonment', 'Lead Paint', 'Slip & Fall', 'Subrogation']

      def initialize(**options)
        start_activities if options[:activities]
        start

      end

      def start
        LitigationCaseTypeIRLKeywords.all().each do |key_cat|
          existed_report_id = LitigationCaseTypeMatchingKeywords.where(keyword: key_cat.keyword).map { |row| row.report_text_id }
          LitigationCaseTypeIRLKeywordToText.where(keyword:key_cat.keyword)
                                            .where.not(report_text_id:existed_report_id).each do |key_to_text|
            case_info = CaseReportAwsText.where(id: key_to_text.report_text_id).first
            LitigationCaseTypeMatchingKeywords.insert({
              court_id: case_info.court_id,
              case_id: case_info.case_id,
              keyword: key_cat.keyword,
              category_name: key_cat.category_name,
              report_text_id: key_to_text.report_text_id,
              pdf_link: key_to_text.pdf_link,
            })

            UsCasePdfsKeywordToText.insert({
                                             keyword: key_cat.category_name,
                                             case_report_text_id: key_to_text.report_text_id,
                                             pdf_link: key_to_text.pdf_link,
                                           })


          end
        end
      end

      def start_activities
        p 'hey'
        LitigationCaseTypeIRLKeywords.all().each do |key_cat|
          existed_activity_id = LitigationCaseActivityDescMatchingKeywords.where(keyword: key_cat.keyword).map { |row| row.activity_id }
          AnalysisLitigationCourtsActivitiesKeywords.where(keyword:key_cat.keyword)
                                                    .where.not(activity_id:existed_activity_id).each do |key_to_text|
            case_info = UsCaseActivities.where(id: key_to_text.activity_id).first
            LitigationCaseActivityDescMatchingKeywords.insert({
                                                        court_id: case_info.court_id,
                                                        case_id: case_info.case_id,
                                                        keyword: key_cat.keyword,
                                                        category_name: key_cat.category_name,
                                                        activity_id: key_to_text.activity_id,
                                                        activity_desc: case_info.activity_decs,
                                                      })


          end
        end
      end



    end


    class ActivitiesAnalysis
      def initialize(**options)
        p 'START activities analysis ...'
        p 'General courts'
        @limit = options[:limit] || 10
        @keywords = keywords || []
        court_ids = options[:court_id] || [51, 25, 14, 36]
        start(court_ids)
        p 'Supreme and Appelate courts'
        #start_saac
        p 'END courthouse analysis ...'
      end

      def start(court_ids)
        p 'Matching words in activity table'
        court_ids = [court_ids] if !court_ids.nil? & !court_ids.kind_of?(Array)
        p court_ids
        @keywords.each do |keyword|
          p keyword
          page = 0
          loop do
            offset = @limit*page
            p page
            activities = UsCaseActivities.where(court_id:court_ids).where("activity_decs rlike '#{keyword}'").limit(@limit).offset(offset)
            report_text_ids = activities.map {|row| row.id}
            existing_activity_id = get_existing_activity_id(keyword, report_text_ids)
            activities.each do |activity|
              next if activity.id.in?(existing_activity_id)

              # pdf_link = activity.file
              # pdf_link = pdf_link.gsub(' ', '%20') if !pdf_link.nil?
              kw_to_db = {
                court_id: activity.court_id,
                case_id: activity.case_id,
                keyword: keyword,
                activity_id: activity.id
              }
              #kw_to_db = get_keywords(keywords_hash, case_text.id, pdf_link)
              AnalysisLitigationCourtsActivitiesKeywords.insert(kw_to_db) #if !kw_to_db.empty?
            end
            page+=1
            break page if activities.to_a.length<@limit
          end
        end

      end

      def get_existing_activity_id(keyword, activity_ids)
        AnalysisLitigationCourtsActivitiesKeywords.where(activity_id: activity_ids).where(keyword:keyword).map {|row| row.activity_id}
      end

      def keywords
        keywords = LitigationCaseTypeIRLKeywords.all().select(:keyword).distinct.map { |row| row.keyword }
        # keywords = UsCaseTypesIRLCategorized.where.not(general_category:nil).select(:general_category).distinct.map { |row| row.general_category  }
        # keywords += UsCaseTypesIRLCategorized.where.not(midlevel_category:nil).select(:midlevel_category).distinct.map { |row| row.midlevel_category  }
        # keywords += UsCaseTypesIRLCategorized.where.not(specific_category:nil).select(:specific_category).distinct.map { |row| row.specific_category  }
        # keywords += UsCaseTypesIRLCategorized.where.not(additional_category:nil).select(:additional_category).distinct.map { |row| row.additional_category  }
        # keywords
      end

    end

  end
end



