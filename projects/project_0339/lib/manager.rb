# frozen_string_literal: true

require_relative 'scraper'
require_relative 'parser'
require_relative '../module/slack_custom'
require_relative '../module/validator'


class Manager
  include SlackCustom
  include Validator

  def download_and_update_licenses
    begin
      Scraper.new.download_csv
    rescue StandardError => e
      logger.debug ('ERROR' * 10).colorize(:red)
      logger.debug e
      logger.debug e.backtrace
    end
    begin
      csv_files_list.each do |csv_file_path|
        begin
          raise 'CSV FILE IS INVALID' unless valid_csv_file?(csv_file_path)
          Keeper.new.upload_csv_data(csv_file_path)
        rescue
          logger.debug 'CSV FILE IS INVALID'
        end
      end
      
    rescue StandardError => e
      logger.debug ('ERROR' * 10).colorize(:red)
      logger.debug e
      logger.debug e.backtrace
    end
    begin
      Keeper.new.update_records
    rescue StandardError => e
      logger.debug ('ERROR' * 10).colorize(:red)
      logger.debug e
      logger.debug e.backtrace
    end
  end

  private

  def csv_files_list
    Dir["#{Hamster::Harvester.new.storehouse}store/**/*.csv"]
  end
end
