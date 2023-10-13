# frozen_string_literal: true
require_relative 'gsearch/g_param'
require_relative 'model/google_console_data_run'
require_relative 'model/google_console_data_config'
require_relative 'powerbi/powerbi'
require_relative 'powerbi/powerbi_update'

module UnexpectedTasks
  module HamsterM24task

    class PowerUpdate
      attr_writer :update_date
      def initialize(*option)

      end

      def update_date=(update_date)
        if update_date.class == String
          @update_date = DateTime.parse(update_date)
        else
          @update_date = update_date
        end
      end

      def data_update_list
        # Необходимо узнать какие там с нулями ?
        # GoogleConsoleData.where(update_at: @update_date, name: @name_profile)
      end

      def run
        @config_powerbi = Storage.new.powerbi
        power_update = PowerBiUpdate.new(@config_powerbi)
        power_update.update_at = @update_date
        power_update.run
      end

      # Static methods
      @auth_mutex = nil
      def self.report message
        puts message.red
        # Hamster.report(to: "Mikhail Golovanov", message: message, use: :telegram)
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
        update_date = '2022-04-15'
        profile = PowerUpdate.new("")
        profile.update_date = update_date
        profile.run

        puts "Import in PowerBi M24"
        end
    end
  end
end