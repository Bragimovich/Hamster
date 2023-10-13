# frozen_string_literal: true

require_relative 'case_types/us_case_types_rachelle_model'

module UnexpectedTasks
  module UsCourts
    class CaseTypesRachelle
      def self.run(**options)
        self.count_tables if options[:count]
        TextResearch.new(**options) if options[:text]
      end

      def self.count_tables
        p 'Count in categorized Rachelle table'
        UsCaseTypesRachelleCategorized.where.not(court_id:nil).each do |row|
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

      KEYWORDS = ['Professional/Disciplinary', 'Contract', 'Real Property', 'Torts', 'Forfeiture/Penalty', 'Labor', 'Debt Collection/Liens', 'Other Statutes', 'Civil Rights', 'Foreclosure', 'Personal Injury', 'Personal Property', 'Rent Lease & Ejectment', "Workers' Compensation", 'Commercial', 'Insurance', 'Consumer Credit', 'Non-commercial', 'All Other Real Property', 'Arbitration', 'Other Contract', 'Employment', 'Breach', 'Medical Malpractice', 'Asbestos Personal Injury Product Liability', 'Redemption', 'Product Liability', 'Motor Vehicle', 'Tax Certiorari', 'Commercial Mortgage', 'Partition', 'Quiet Title', 'Assault, Libel, & Slander', 'Conversion', 'Dog Bite', 'Premises', 'Other Fraud', 'Nursing Home', 'Other Personal Injury', 'Property Damage Product Liability', '"Negligent Hiring, Supervision, or Retention"', 'Wrongful Death', 'Legal Malpractice', 'False Arrest or Imprisonment', 'Lead Paint', 'Slip & Fall', 'Subrogation']

      def initialize(**options)
        @limit = options[:limit] ? options[:limit] : 100
        start_time = Time.now().to_i
        @keywords = keywords.uniq | KEYWORDS
        matching_words
        end_time = Time.now().to_i
        puts "Time for finish #{@limit} rows: #{end_time-start_time} seconds"
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

            UsCaseReportRachelle.insert_all([{
                                     court_id: row.court_id,
                                     case_id: row.case_id,
                                     activity_id: row.activity_id,
                                     top5_matches: keywords_hash2.to_s
                                   }])

          end
          page+=1
          break if cases.to_a.length<@limit
        end

      end

      def how_many_words(text)
        words = {}

        @keywords.each do |keyword|
          next if keyword.in?(words)
          count = text.scan(keyword).size
          words[keyword] = count if count>0
        end

        words

      end

      private

      def keywords
        keywords = UsCaseTypesRachelleCategorized.where.not(general_category:nil).select(:general_category).distinct.map { |row| row.general_category  }
        keywords += UsCaseTypesRachelleCategorized.where.not(midlevel_category:nil).select(:midlevel_category).distinct.map { |row| row.midlevel_category  }
        keywords += UsCaseTypesRachelleCategorized.where.not(specific_category:nil).select(:specific_category).distinct.map { |row| row.specific_category  }
        keywords += UsCaseTypesRachelleCategorized.where.not(additional_category:nil).select(:additional_category).distinct.map { |row| row.additional_category  }
      end


    end


  end
end



