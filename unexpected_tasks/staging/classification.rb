require_relative 'models/staging_cases_to_classifications'
require_relative 'sql/classification_sql'
require_relative 'tools/message_send'

module UnexpectedTasks
  module Staging
    class Classification
      def self.run(**options)
        title = 'Staging | Cases to classification'
        start_count = StagingCasesToClassifications.all.count
        StagingCasesToClassifications.connection.execute(type)
        StagingCasesToClassifications.connection.execute(category)
        StagingCasesToClassifications.connection.execute(subcategory)
        StagingCasesToClassifications.connection.execute(additional)
        end_count = StagingCasesToClassifications.all.count
        message = "Add `#{end_count - start_count}` new relations."
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