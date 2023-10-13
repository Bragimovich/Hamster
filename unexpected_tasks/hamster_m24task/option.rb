# frozen_string_literal: true
require_relative 'gsearch/g_param'
require_relative 'model/google_console_data_run'
require_relative 'model/google_console_data_config'
require_relative 'sheet/scpread_sheet'
module UnexpectedTasks
  module HamsterM24task

    class Option
      @auth_mutex = nil
      def self.report message
        Hamster.report(to: "Mikhail Golovanov", message: message, use: :telegram)
      end

      def self.thread_run conf
        date_end = GoogleConsoleData.select("DATE(MIN(start_date)) AS start_date").where(name: conf.name).first.start_date
        # date_start += 1 unless date_start.nil?
        date_start = Date.parse("01-07-2021")
        # date_end = Date.today - 2

        while date_start < date_end
          begin
            self.report(conf.name)
            run = GoogleConsoleDataRun.find_by(status: ["sites_ok", "processing"], media: conf.name)
            run = GoogleConsoleDataRun.create(media: conf.name, start_date: date_start, end_date: (date_start)) if run.nil?
            puts "Start Process #{run.id}"
            rem = GParam.new
            rem.run_id = run.id
            rem.media = conf.name
            rem.start_date = date_start.strftime("%Y-%m-%d")
            rem.end_date = (date_start).strftime("%Y-%m-%d")
            retry_count = 5
            begin
              @auth_mutex.synchronize do
                rem.credentials = OpenStruct.new(conf.get_token)
              end if rem.credentials.nil?

              if (run.status.include?("processing"))
                self.report(conf.name.to_s + "Proccessing")
                if rem.sites
                  retry_count = 5
                  run.status = "sites_ok"
                  run.save
                else
                  raise "Not auth " + rem.media.to_s
                end
              end

              if (run.status.include?("sites_ok"))
                self.report(config.name.to_s + "sites_ok")
                if rem.params
                  retry_count = 5
                  run.status = "finish"
                  run.save
                else
                  raise "Not auth " + rem.media.to_s
                end
              end

            rescue StandardError => error
              puts error.to_s.red
              report error.to_s.red
              # sleep 600
              @auth_mutex.synchronize do
                rem.credentials = OpenStruct.new(conf.get_token)
              end
              retry if (retry_count -= 1) > 0
            end

          rescue StandardError => error
            text_err = error.message
            trace = error.backtrace.to_s
            message = text_err + trace
            Hamster.report(to: "Mikhail Golovanov", message: message, use: :telegram)
          end
          date_start = date_start + 1
        end
      end

      def self.config
        @config = GoogleConsoleDataConfig.all
      end

      def self.thread_spreadsheet conf
        sheet = SpreadSheetLocy.new
        sheet.config = conf
        sheet.run
      end

      def self.run
        self.report "Start M24"

        #TODO: RUN
        #Get clients key files
        @auth_mutex = Mutex.new
        self.config
        @thread = []

        @config.each do |conf|
          @thread << Thread.new(conf) do |conf|
          self.thread_run(conf)
          # self.thread_spreadsheet(conf)
          end

          Hamster.report(to: "Mikhail Golovanov", message: "Wait Thread M24", use: :telegram)
        end
        @thread.each &:join
        Hamster.report(to: "Mikhail Golovanov", message: "Finish Process M24", use: :telegram)

      end
    end

  end
end
