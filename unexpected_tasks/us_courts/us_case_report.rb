# frozen_string_literal: true

# include Hamster::Loggable
require_relative 'us_case_table_analysis/us_case_table_analysis_models'

TABLES = ['us_case_info', 'us_saac_case_info']
TEST_CHANNEL = 'C043GSQCVMY'
US_COURTS_TASK_CHANNEL = 'C03CU5656JY'
OLEKSII_KUTS = 'U03F2H0PB2T'
STARS = "\n#{'*'*77}"

NAMES = "<@#{OLEKSII_KUTS}>\n"
PERIOD_NAME = {"7" => 'week', "14" => '2 weeks', "28" => '4 weeks', "91" => 'quarter'}
WEEK = 7

module UnexpectedTasks
  module UsCourts
    class UsCaseReport < Hamster::Harvester
      def self.run(**options)
        @_s_    = Storage.new
        Slack.configure do |config|
          config.token = @_s_.slack
          raise 'Missing Slack API token!' unless config.token
        end
        manager = UsCaseReportManager.new(options)
        manager.run if options[:run] || options[:auto]
        manager.check if options[:check] || options[:auto]
      rescue StandardError => e
        Slack::Web::Client.new.chat_postMessage(
          channel: OLEKSII_KUTS,
          text: "us_case_report EXCEPTION: #{e}\n#{e.backtrace}",
          as_user: true)
        exit 1
      end
    end
# ===============================================
    class UsCaseReportManager < Hamster::Harvester
      def initialize(options)
        super
        clear_log if options[:clear_log]

        period = options[:period]
        @keeper = Keeper.new
        @now = Time.now.to_date.beginning_of_week
        @period = period.to_s.in?(PERIOD_NAME.keys) ? period : WEEK
      end

      def clear_log
        File.open(logger.instance_variable_get(:@logdev).filename, 'w') {}
      end

      def run
        start = @keeper.last_date
        first_record = @keeper.select('CAST(created_at AS DATE)', 'us_case_info', '1=1 order by id limit 1').flatten.first if start.nil?
        start ||= first_record.beginning_of_week

        loop do
          @keeper.update_instance_variables
          break if (ending = start + @period) > @now

          TABLES.each do |table_name|
            count = @keeper.select('court_id, count(id)', table_name, "created_at >= '#{start}' and created_at < '#{ending}' group by court_id")
            arr = count.map do |row|
              median_array = @keeper.total_array(row[0])
                                    .push(row[1])
                                    .sort
              total = median_array.sum
              first_date = @keeper.first_date(row[0]) || start
              { :court_id         => row[0],
                :number_of_cases  => row[1],
                :period           => PERIOD_NAME[@period.to_s],
                :start_of_period  => start,
                :end_of_period    => ending,
                :average          => total.div( (ending - first_date) / @period ),
                :median           => median_array[median_array.size/2] }
            end
            arr
            @keeper.store(arr)
          end

          start += @period
        end
      end

      def check
        report_list = @keeper.last_period_data

        # remove from list not needed courts
        checking_courts = @keeper.to_report
        report_list.filter! { |el| checking_courts.include?(el[0]) }
        report_list.filter! { |el| el[3].div(el[1]) >= 2 || outdated?(el[4]) }

        report_list.each { |line| logger.debug(line) }
        alert_report = generate_report(report_list)
        alert_report.each { |line| logger.info(line) }

        send_to_slack(alert_report) if @keeper.updated?
      end

      def send_to_slack(alert_report)
        (0..alert_report.size.pred).step(35) do |i|
          Slack::Web::Client.new.chat_postMessage(
            channel: TEST_CHANNEL,
            text: "#{NAMES if i == 0}```\n" + alert_report[i..(i+34)].join("\n") + "```\n",
            as_user: true)
        end
      end

      def generate_report(report_list)
        courts_names = @keeper.courts_names
        report_list.map do |row|
          text = outdated?(row[4]) ? "no cases since #{row[4]}" : "new cases: #{row[1]} / #{row[3]} < 50%"
          court_data = courts_names[row[0]]
          res = "[" + row[0].to_s.rjust(3) + "] #{court_data[0]}: ".ljust(60) + "#{text}".ljust(30) + " by #{court_data[1]}"
          (@now - row[4]) > (30 + @period) ? res.gsub(' ', '-') : res
        end
      end

      def actual?(end_of_period)
        (@now - end_of_period) < @period
      end

      def outdated?(end_of_period)
        !actual?(end_of_period)
      end
    end
# ===============================================
    class Keeper < Hamster::Harvester
      def initialize
        super
        @total_array = []
        @first_date = {}
      end

      def update_instance_variables
        sql = "SELECT court_id, number_of_cases FROM `us_case_courthouse_average_counts` WHERE court_id IS NOT NULL"
        logger.info("#{STARS}\n#{sql}")
        @total_array = UsCaseCourthouseAverageCounts.connection.execute(sql).to_a.sort
        sql = "SELECT court_id, min(start_of_period) FROM `us_case_courthouse_average_counts` WHERE court_id IS NOT NULL GROUP BY court_id"
        logger.info("#{STARS}\n#{sql}")
        @first_date = UsCaseCourthouseAverageCounts.connection.execute(sql).to_a.to_h
      end

      def select(field, table, condition)
        sql = "SELECT #{field} from `#{table}` where #{condition}"
        logger.info("#{STARS}\n#{sql}")
        UsCaseInfo.connection.execute(sql).to_a
      end

      def total_array(court_id)
        @total_array.map {|el| el[1] if el[0].eql?(court_id)}.compact
      end

      def first_date(court_id)
        @first_date[court_id]
      end

      def last_date
        sql = "SELECT end_of_period FROM `us_case_courthouse_average_counts` order by id desc limit 1"
        logger.info("#{STARS}\n#{sql}")
        UsCaseCourthouseAverageCounts.connection.execute(sql).to_a.flatten.first
      end

      def store(records)
        UsCaseCourthouseAverageCounts.insert_all(records) if !records.empty?
      end

      def last_period_data
        sql = <<~SQL
          SELECT court_id, number_of_cases, average, median, end_of_period
            FROM `us_case_courthouse_average_counts`
           WHERE id IN (
                SELECT max(id)
                  FROM us_case_courthouse_average_counts
                 WHERE court_id IS NOT NULL
                 GROUP BY court_id);
        SQL
        logger.info("#{STARS}\n#{sql}")
        UsCaseCourthouseAverageCounts.connection.execute(sql).to_a.sort
      end

      def to_report
        sql = "SELECT court_id FROM `us_courts_table` where to_report = true"
        logger.info("#{STARS}\n#{sql}")
        UsCaseInfo.connection.execute(sql).to_a.flatten
      end

      def courts_names
        sql = "SELECT court_id, court_name, created_by FROM `us_courts_table`"
        logger.info("#{STARS}\n#{sql}")
        UsCaseInfo.connection.execute(sql).to_a.map {|el| [el[0], el[1..2]]}.to_h
      end

      def updated?
        UsCaseCourthouseAverageCounts.last.created_at > Time.now.to_date.beginning_of_week
      end
    end
  end
end
