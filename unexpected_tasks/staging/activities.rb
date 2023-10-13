require_relative 'models/raw_activities'
require_relative 'models/raw_activities_saac'
require_relative 'models/staging_courts'
require_relative 'models/staging_cases'
require_relative 'models/staging_activities'
require_relative 'sql/activities_sql'
require_relative 'tools/message_send'

module UnexpectedTasks
  module Staging
    class Activities
      def self.run(**options)
        limit = 10000
        iterations = 20
        title = 'Staging | Activities'
        @index = 0
        start_count = StagingActivities.all.count
        courts = StagingCases.connection.execute(courts('us_case_info')).to_a.sort
        courts.each do |court|
          raw_court = court[0]
          court = court[1]
          Hamster.logger.info "Raw Court #{raw_court} | Court #{court}".blue
          (1..iterations).each do |iteration|
            Hamster.logger.info "Iteration #{iteration}".blue
            activities = RawActivities.connection.execute(raw_activities(limit, court, raw_court))
            break if activities.to_a.blank?
            plunk(activities, 'us_case_activities')
          end
        end
        courts = StagingCases.connection.execute(courts('us_saac_case_info')).to_a.sort
        courts.each do |court|
          raw_court = court[0]
          court = court[1]
          Hamster.logger.info "Raw Court #{raw_court} | Court #{court}".blue
          (1..iterations).each do |iteration|
            Hamster.logger.info "Iteration #{iteration}".blue
            activities = RawActivitiesSaac.connection.execute(raw_activities_saac(limit, court, raw_court))
            break if activities.to_a.blank?
            plunk(activities, 'us_saac_case_activities')
          end
        end
        end_count = StagingActivities.all.count
        message = "Add `#{end_count - start_count}` new activities."
        Hamster.logger.info message
        message_send(title, message)
      rescue => e
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        Hamster.logger.error e.full_message
        message_send(title, message)
      end

      def self.plunk(activities, external_table)
        activities.each do |activity|
          @index += 1
          external_id = activity[0]
          date = activity[3]
          description = activity[4]
          description = description.blank? ? nil : description.gsub('Â ','').gsub(' ','').gsub(/\s/, ' ').squeeze(' ').strip
          type = activity[5]
          type = type.blank? ? nil : type.gsub('Â ','').gsub(/\s/, ' ').squeeze(' ').strip[0..125]
          pdf = activity[6]
          generated_uuid = activity[7]
          raw_court_id = activity[1]
          raw_case_id = activity[2]
          raw_case_id = raw_case_id.blank? ? nil : raw_case_id.strip
          court_id = StagingCourts.where(external_id: raw_court_id).select(:id)
          court_id = court_id.blank? ? nil : court_id[0][:id]
          case_id = StagingCases.connection.execute(case_id(raw_case_id, court_id)).to_a
          case_id = case_id.blank? ? nil : case_id[0][0]
          next if case_id.blank?
          hash = {
            external_id: external_id,
            external_table: external_table,
            court_id: court_id,
            case_id: case_id,
            date: date,
            description: description,
            type: type,
            pdf: pdf,
            generated_uuid: generated_uuid,
            created_by: 'Igor Sas'
          }
          insert_activities(hash)
        end
      end

      def self.insert_activities(hash)
        check = StagingActivities.where("external_id = \"#{hash[:external_id]}\" AND external_table = \"#{hash[:external_table]}\"").select(:external_id)
        if check.blank?
          StagingActivities.insert(hash)
          Hamster.logger.info "[#{@index}][#{hash[:external_table]}][#{hash[:external_id]}] ADD IN DATABASE!".green
        else
          Hamster.logger.info "[#{@index}][#{hash[:external_table]}][#{hash[:external_id]}] ALREADY IN DATABASE!".yellow
        end
      end
    end
  end
end