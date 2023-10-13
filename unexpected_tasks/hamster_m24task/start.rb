# frozen_string_literal: true
require_relative 'gsearch/g_param'
require_relative 'model/google_console_data_run'
require_relative 'model/google_console_data_config'
require_relative 'sheet/scpread_sheet'
require_relative 'powerbi/powerbi_update'
require_relative 'powerbi/powerbi_matomo'
require_relative 'powerbi/powerbi_matomo_last_record'
require_relative 'powerbi/powerbi_matomo_statistics'

module UnexpectedTasks
  module HamsterM24task

    class Start
      @auth_mutex = nil

      def self.report message
        Hamster.report(to: "Mikhail Golovanov", message: message, use: :telegram)
        puts message
      end

      def self.thread_run_is_null conf
        #SELECT t0.id, run_id, name, url, t0.start_date, md5_hash, t1.start_date AS t1_start_date FROM google_console_data as t0 LEFT JOIN google_console_data_runs AS t1 ON  run_id = t1.id AND t0.name = t1.media WHERE click_total IS NULL AND impressions_total IS NULL;
        #SELECT t0.*, t1.start_date AS t1_start_date FROM google_console_data as t0 LEFT JOIN google_console_data_runs AS t1 ON  run_id = t1.id AND t0.name = t1.media WHERE click_total = 0 AND impressions_total = 0;
        rem = GParam.new
        rem.media = conf.name

        retry_count = 5
        begin
          @auth_mutex.synchronize do
            rem.credentials = OpenStruct.new(conf.get_token)
          end if rem.credentials.nil?

          if rem.params_is_null
            retry_count = 5
          else
            raise "Not auth " + rem.media.to_s
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
      end

      def self.thread_run_is_zero conf
        rem = GParam.new
        rem.media = conf.name

        retry_count = 5
        begin
          @auth_mutex.synchronize do
            rem.credentials = OpenStruct.new(conf.get_token)
          end if rem.credentials.nil?

          if rem.params_is_zero
            retry_count = 5
          else
            raise "Not auth " + rem.media.to_s
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
      end

      def self.thread_run conf

        date_start = GoogleConsoleData.select("DATE(MAX(start_date)) AS start_date").where(name: conf.name).first.start_date
        date_start += 1 unless date_start.nil?
        date_start = Date.today << 3 if date_start.nil?
        date_end = Date.today - 2

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
            report(message: message)
          end
          date_start = GoogleConsoleData.select("DATE(MAX(start_date)) AS start_date").where(name: conf.name).first.start_date + 1
        end
      end

      def self.config
        @config = GoogleConsoleDataConfig.all
      end

      def self.run(**options)

        puts "Export from Google"

        #Get clients key files
        @auth_mutex = Mutex.new
        self.config
        @config_powerbi = Storage.new.powerbi
        @thread = []

        # if !options[:fix_motomo].nil?
        #   PowerBiLastRecord.new(@config_powerbi).run
        # elsif options[:stat]
        #   PowerBiStatistics.new(@config_powerbi).run
        # else
        #

        #ADD DATA:
        @config.each do |conf|
          @thread << Thread.new(conf) do |conf|
            self.thread_run(conf)
          end
          Hamster.report(to: "Mikhail Golovanov", message: "Wait Thread M24 " + conf.name, use: :telegram)
        end
        @thread.each &:join
        #END

        @thread = []
        #UPDATE DATA
        @config.each do |conf|
          @thread << Thread.new(conf) do |conf|
            self.thread_run_is_null(conf);
          end
          Hamster.report(to: "Mikhail Golovanov", message: "Wait Thread M24 Update NULL records " + conf.name, use: :telegram)
        end

        @thread.each &:join

        @thread = []
        #UPDATE DATA
        @config.each do |conf|
          @thread << Thread.new(conf) do |conf|
            self.thread_run_is_zero(conf);
          end
          Hamster.report(to: "Mikhail Golovanov", message: "Wait Thread M24 Update ZERO records " + conf.name, use: :telegram)
        end

        @thread.each &:join

        puts "Import in PowerBi M24"

        PowerBiReports.new(@config_powerbi).run

        PowerBiReportsMatomo.new(@config_powerbi).run

        PowerBiStatistics.new(@config_powerbi).run
        # end
      end
    end
  end
end