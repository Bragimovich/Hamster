require_relative 'models/raw_cases'
require_relative 'models/raw_cases_saac'
require_relative 'models/raw_activities'
require_relative 'models/raw_activities_saac'
require_relative 'models/raw_pdfs_on_aws'
require_relative 'models/raw_pdfs_on_aws_saac'
require_relative 'models/staging_cases'
require_relative 'models/staging_courts'
require_relative 'sql/cases_sql'
require_relative 'tools/message_send'

module UnexpectedTasks
  module Staging
    class Cases
      def self.run(**options)
        limit = 1500
        title = 'Staging | Cases'
        @index = 0
        start_count = StagingCases.all.count
        20.times do
          cases = RawCases.connection.execute(raw_cases(limit))
          break if cases.to_a.blank?
          plunk(cases, 'us_case_info')
        end
        20.times do
          cases = RawCasesSaac.connection.execute(raw_cases_saac(limit))
          break if cases.to_a.blank?
          plunk(cases, 'us_saac_case_info')
        end
        StagingCases.connection.execute(uuid)
        StagingCases.connection.execute(categories_from_raw_type)
        #StagingCases.connection.execute(categories_from_description)
        StagingCases.connection.execute(categories_from_text)
        StagingCases.connection.execute(categories_from_pdf_text)
        StagingCases.connection.execute(categories_from_keywords_general)
        StagingCases.connection.execute(categories_from_keywords_midlevel)
        StagingCases.connection.execute(categories_from_keywords_specific)
        StagingCases.connection.execute(categories_from_keywords_additional)
        end_count = StagingCases.all.count
        message = "Add `#{end_count - start_count}` new cases."
        Hamster.logger.info message
        message_send(title, message)
      rescue => e
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        Hamster.logger.error e.full_message
        message_send(title, message)
      end

      def self.plunk(cases, external_table)
        cases.each do |case_item|
          @index += 1
          external_id = case_item[0]
          raw_id = case_item[2]
          raw_id = raw_id.blank? ? nil : raw_id.strip
          name = case_item[3]
          name = name.blank? ? nil : name.to_s.gsub(/\s/, ' ').squeeze(' ').strip
          filled_date = case_item[4]
          filled_date = filled_date.blank? ? nil : filled_date.to_s.squeeze(' ').split(' ')[0]
          if !filled_date.blank? && filled_date.include?('/')
            filled_date = Date.strptime(filled_date, '%m/%d/%y')
          else
            filled_date = filled_date.blank? ? nil : Date.parse(filled_date)
          end
          status = case_item[7]
          status = status.blank? ? nil : status.to_s.gsub(/\s/, ' ').squeeze(' ').strip[0..63]
          raw_type = case_item[5]
          raw_type = raw_type.blank? ? nil : raw_type.to_s.gsub(/\s/, ' ').squeeze(' ').strip[0..63]
          description = case_item[6]
          description = description.blank? ? nil : description.to_s.gsub(/\s/, ' ').squeeze(' ').strip
          data_source_url = case_item[8]
          data_source_url = data_source_url.blank? ? nil : data_source_url
          raw_court_id = case_item[1]
          court_id = StagingCourts.where(external_id: raw_court_id).select(:id)
          court_id = court_id.blank? ? nil : court_id[0][:id]
          if court_id.blank?
            Hamster.logger.error "court id blank!\n#{case_item}".red
            next
          end
          type = case_item[10]
          type = type.blank? ? nil : type.strip
          category = case_item[11]
          category = category.blank? ? nil : category.strip
          subcategory = case_item[12]
          subcategory = subcategory.blank? ? nil : subcategory.strip
          additional_subcategory = case_item[13]
          additional_subcategory = additional_subcategory.blank? ? nil : additional_subcategory.strip
          priority = case_item[9]
          priority = priority.blank? ? nil : priority.strip
          if external_table == 'us_case_info'
            complaint_pdf = RawActivities.connection.execute(raw_complaint(raw_id, raw_court_id)).to_a
            complaint_pdf = complaint_pdf.blank? ? nil : complaint_pdf[0][0]
            appeal_pdf = RawActivities.connection.execute(raw_appeal(raw_id, raw_court_id)).to_a
            appeal_pdf = appeal_pdf.blank? ? nil : appeal_pdf[0][0]
            summary_pdf = RawPdfsOnAws.connection.execute(raw_summary(raw_id, raw_court_id)).to_a
            summary_pdf = summary_pdf.blank? ? nil : summary_pdf[0][0]
          elsif external_table == 'us_saac_case_info'
            complaint_pdf = RawActivitiesSaac.connection.execute(raw_complaint_saac(raw_id, raw_court_id)).to_a
            complaint_pdf = complaint_pdf.blank? ? nil : complaint_pdf[0][0]
            appeal_pdf = RawActivitiesSaac.connection.execute(raw_appeal_saac(raw_id, raw_court_id)).to_a
            appeal_pdf = appeal_pdf.blank? ? nil : appeal_pdf[0][0]
            summary_pdf = RawPdfsOnAwsSaac.connection.execute(raw_summary_saac(raw_id, raw_court_id)).to_a
            summary_pdf = summary_pdf.blank? ? nil : summary_pdf[0][0]
          else
            complaint_pdf = nil
            appeal_pdf = nil
            summary_pdf = nil
          end
          hash = {
            external_id: external_id,
            external_table: external_table,
            court_id: court_id,
            raw_id: raw_id,
            name: name,
            filled_date: filled_date,
            status: status,
            raw_type: raw_type,
            type: type,
            category: category,
            subcategory: subcategory,
            additional_subcategory: additional_subcategory,
            priority: priority,
            description: description,
            summary_pdf: summary_pdf,
            complaint_pdf: complaint_pdf,
            appeal_pdf: appeal_pdf,
            data_source_url: data_source_url,
            created_by: 'Igor Sas'
          }
          insert_cases(hash)
        end
      end
      def self.insert_cases(hash)
        check = StagingCases.where("raw_id = \"#{hash[:raw_id]}\" AND court_id = \"#{hash[:court_id]}\" AND external_table = \"#{hash[:external_table]}\"").select(:id, :external_id)
        if check.blank?
          StagingCases.insert(hash)
          Hamster.logger.info "[#{@index}][#{hash[:external_table]}][#{hash[:external_id]}] ADD IN DATABASE!".green
        else
          if hash[:external_id] > check[0][:external_id]
            StagingCases.where("id = #{check[0][:id]}").update(hash)
            Hamster.logger.info "[#{@index}][#{hash[:external_table]}][#{hash[:external_id]}] UPDATE IN DATABASE!".blue
          else
            Hamster.logger.info "[#{@index}][#{hash[:external_table]}][#{hash[:external_id]}] ALREADY IN DATABASE!".yellow
          end
        end
        if hash[:external_table] == 'us_case_info'
          RawCases.where("id = #{hash[:external_id]}").update(checked: 1)
          Hamster.logger.info "   [#{hash[:external_table]}][#{hash[:external_id]}] UPDATE CHECKED = 1 IN DATABASE!".blue
        elsif hash[:external_table] == 'us_saac_case_info'
          RawCasesSaac.where("id = #{hash[:external_id]}").update(checked: 1)
          Hamster.logger.info "   [#{hash[:external_table]}][#{hash[:external_id]}] UPDATE CHECKED = 1 IN DATABASE!".blue
        end
      end
    end
  end
end