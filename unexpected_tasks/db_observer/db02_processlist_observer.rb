# frozen_string_literal: true

# require_relative 'us_case_table_analysis/us_case_table_analysis_models'
require_relative './models/db_observer_models'

OLEKSII_KUTS = 'U03F2H0PB2T'


module UnexpectedTasks
  module DbObserver
    class Db02ProcesslistObserver
      def self.run(**options)
        @_s_    = Storage.new
        Slack.configure do |config|
          config.token = @_s_.slack
          raise 'Missing Slack API token!' unless config.token
        end
        manager = DB02ProcesslistManager.new
        manager.run if options[:run] || options[:auto]
        manager.check if options[:check] || options[:auto]
      rescue StandardError => e
        Slack::Web::Client.new.chat_postMessage(
          channel: OLEKSII_KUTS,
          text: "Scraped_DB_Tables_Checker EXCEPTION: #{e}",
          as_user: true)
        puts ['*'*77,  e.backtrace]
        exit 1
      end
    end

    class DB02ProcesslistManager
      def run
        processlist = ScrapeTasksAttachedTables.connection.execute("SHOW full processlist").to_a
        keys = DB02Processlists.column_names[1..-5]
        data = processlist.map {|row| Hash[keys.zip(row)]} # array of arrays -=> array of hashes (for ActiveRecord::Base.insert_all)
        DB02Processlists.insert_all(data)
        DB02Processlists.insert({info: "#{data.size} rows in set"})

        ScrapeTasksAttachedTables.connection.close
        DB02Processlists.connection.close
      end

      def check
      end
    end
  end
end
