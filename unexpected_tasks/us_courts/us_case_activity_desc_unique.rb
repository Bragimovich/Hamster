# frozen_string_literal: true

require_relative 'us_case_table_analysis/us_case_table_analysis_models'

INSERT_ALL_SIZE = 10_000
SELECT_LIMIT = 1_000_000
OLEKSII_KUTS = 'U03F2H0PB2T'
STARS = "\n#{'*'*77}"

module UnexpectedTasks
  module UsCourts
    class UsCaseActivityDescUnique < Hamster::Harvester
      def self.run(**options)
        @_s_    = Storage.new
        Slack.configure do |config|
          config.token = @_s_.slack
          raise 'Missing Slack API token!' unless config.token
        end
        manager = UsCaseActivityDescUniqueManager.new(options)
        manager.run if options[:run] || options[:auto]
        manager.check if options[:check] || options[:auto]
      rescue StandardError => e
        Slack::Web::Client.new.chat_postMessage(
          channel: OLEKSII_KUTS,
          text: "us_case_activity_desc_unique EXCEPTION: #{e}\n#{e.backtrace}",
          as_user: true)
        exit 1
      end
    end
# ===============================================
    class UsCaseActivityDescUniqueManager < Hamster::Harvester
      def initialize(options)
        super
        clear_log if options[:clear_log]
        @keeper = Keeper.new
      end

      def clear_log
        File.open(logger.instance_variable_get(:@logdev).filename, 'w') {}
      end

      def run
        last_id = @keeper.last_id(@keeper.last_record)
        new_records = @keeper.records_after(last_id).uniq
        logger.info("new records size: #{new_records.size}")
        arr = new_records.map do |row|
          { :activity_desc => row }
        end
        @keeper.store(arr)
      end

      def check
      end
    end
# ===============================================
    class Keeper < Hamster::Harvester
      def last_record
        sql = "SELECT activity_desc, created_at FROM `activity_desc_unique` order by id desc limit 1"
        logger.info("#{STARS}\n#{sql}")
        ActivityDescUnique.connection.execute(sql).to_a.flatten
      end

      def last_id(last_record)
        quote_symbol = last_record[0].include?("'") ? "\"" : "'"
        sql = "SELECT min(id) FROM `us_case_activities` where activity_decs = #{quote_symbol}#{last_record[0]}#{quote_symbol} and created_at <= '#{last_record[1]}' group by created_at order by id desc limit 1"
        logger.info("#{STARS}\n#{sql}")
        UsCaseInfo.connection.execute(sql).to_a.flatten.first
      end

      def records_after(last_id)
        sql = "SELECT activity_decs FROM `us_case_activities` where id > #{last_id} and activity_decs is not null limit #{SELECT_LIMIT}"
        logger.info("#{STARS}\n#{sql}")
        UsCaseInfo.connection.execute(sql).to_a.flatten
      end

      def store(records) # paginate array to avoid isert_all overloading
        (0..records.size).step(INSERT_ALL_SIZE) do |offset|
          data_block = records[offset..offset+INSERT_ALL_SIZE.pred]
          ActivityDescUnique.insert_all(data_block) if !data_block.empty?
        end
      end
    end

  end
end
