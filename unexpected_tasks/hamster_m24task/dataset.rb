# frozen_string_literal: true
require_relative 'model/google_console_data_run'
require_relative 'model/google_console_data'
require_relative 'model/google_console_data_top_query'
require_relative 'model/google_console_data_top_page'
require_relative 'powerbi/powerbi'

module UnexpectedTasks
  module HamsterM24task

    class Dataset
      def self.report message
        Hamster.report(to: "Mikhail Golovanov", message: message, use: :telegram)
      end

      def self.run

        self.report "Start M24 DataSet in PowerBi"

        #TODO: RUN

        #Get clients key files
        # @root_dir = Dir.pwd
        # @client_json_dir = @root_dir + "/client"
        # @client_auth_file = Dir.glob(@client_json_dir + "/*.json")
        # @media_arr = @client_auth_file.map { |item| { "media" => item.split("/").last.split(".").first, "file" => item } }
        PowerBiReports.new.run
        begin
          #Begin: Start Code
          # PowerBiReports.new.run
          #End: End Code
        rescue StandardError => error
          text_err = error.message
          trace = error.backtrace.to_s
          message = text_err + trace
          Hamster.report(to: "Mikhail Golovanov", message: message, use: :telegram)
        end

        Hamster.report(to: "Mikhail Golovanov", message: "Finish Process M24", use: :telegram)
      end
    end
  end
end
