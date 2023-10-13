require_relative 'models/raw_courts'
require_relative 'models/staging_courts'
require_relative 'sql/courts_sql'
require_relative 'tools/message_send'

module UnexpectedTasks
  module Staging
    class Courts
      def self.run(**options)
        title = 'Staging | Courts'
        start_count = StagingCourts.all.count
        courts = RawCourts.connection.execute(raw_courts)
        courts.each do |court|
          court_name = court[1]
          court_name = court_name.blank? ? nil : court_name
          court_id = court[0]
          court_id = court_id.blank? ? nil : court_id
          court_state = court[2]
          court_state = court_state.blank? ? nil : court_state
          court_type = court[3]
          court_type = court_type.blank? ? nil : court_type
          court_sub_type = court[4]
          court_sub_type = court_sub_type.blank? ? nil : court_sub_type
          hash = {
            external_id: court_id,
            is_appealed: 0,
            name: court_name,
            state: court_state,
            type: court_type,
            sub_type: court_sub_type,
            created_by: 'Igor Sas'
          }
          check = StagingCourts.where("external_id = '#{court_id}'").to_a
          if check.blank?
            StagingCourts.insert(hash)
            Hamster.logger.info "[#{court_id}] ADD IN DATABASE!".green
          else
            Hamster.logger.info "[#{court_id}] ALREADY IN DATABASE!".yellow
          end
        end
        end_count = StagingCourts.all.count
        message = "Add `#{end_count - start_count}` new courts."
        Hamster.logger.info message
        message_send(title, message)
      rescue => e
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        Hamster.logger.error e.full_message
        message_send(title, message)
      end
    end
  end
end