# frozen_string_literal: true

require_relative 'scraper'
require_relative 'parser'
require_relative 'keeper'
require_relative '../models/pa_campaign_finance_contributions_new_csv'
require_relative '../modules/slack_custom'

class Manager
  include SlackCustom

  DOMAIN_URL = 'https://www.dos.pa.gov'
  ZIP_FILE_NAME = '2022.zip'
  LIMIT_UNZIP_ATTEMPTS = 25

  def initialize
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download_csv
    begin
      if new_csv_uploaded?
        scrape_new_csv
        send_slack_msg("NEW CSV UPLOADED", to_channel: true)
      end
    rescue StandardError => e
      p e
      p e.backtrace
      send_slack_msg("#{e}")
      send_slack_msg("#{e.backtrace}")
      raise e
    end
  end

  private

  def new_csv_uploaded?
    response = @scraper.scrape_csv_zip_page
    @report_date = @parser.parse_csv_publication_date(response.body)
    previous_date = PaCampaignFinanceContributionsNewCsv.select('distinct(report_date)')
                                                        .sort_by(&:report_date).last.report_date

    return true if @report_date > previous_date

    false
  end

  def scrape_new_csv
    response = @scraper.scrape_csv_zip_page
    zip_url  = @parser.parse_csv_url(response.body)

    1.upto(LIMIT_UNZIP_ATTEMPTS) do |i|
      @scraper.download_zip_file("#{DOMAIN_URL}#{zip_url}", ZIP_FILE_NAME)
      break if @scraper.unzip_csv_files(ZIP_FILE_NAME)

      @scraper.remove_all_files_in_store
      raise 'Unable to download and unzip files with data' if i >= LIMIT_UNZIP_ATTEMPTS
    end

    @keeper.load_committees("#{@scraper.storehouse}/store/#{@parser.committees_file_name}",
                            @report_date)
    @keeper.load_contributions("#{@scraper.storehouse}/store/#{@parser.contributions_file_name}",
                               @report_date)
    @keeper.load_expenditures("#{@scraper.storehouse}/store/#{@parser.expenditures_file_name}",
                              @report_date)
    @scraper.remove_local_csv_files
    @scraper.move_zip_to_trash(ZIP_FILE_NAME)
  end
end
