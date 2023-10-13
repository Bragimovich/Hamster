# frozen_string_literal: true

require_relative 'lib/scraper'
require_relative 'lib/manager'

def scrape(options)
  # Script can't download candidates now
  # This option is not available now
  #
  # if options[:download]
  #   begin
  #     Scraper.new.scrape_candidates
  #   rescue StandardError => e
  #     report to: 'anton.storchak', message: "pa_campaign_finance EXCEPTION: #{e}"
  #     report to: 'anton.storchak', message: "pa_campaign_finance EXCEPTION: #{e.backtrace}"
  #     p ('ERROR' * 10).colorize(:red)
  #     p e.to_s.colorize(:red)
  #     p e.backtrace.to_s.colorize(:red)
  #     exit 0
  #   end
  #   exit 0
  # end

  if options[:download_csv]
    begin
      Manager.new.download_csv
    rescue StandardError => e
      # report to: 'anton.storchak', message: "pa_campaign_finance_download_csv EXCEPTION: #{e}"
      # report to: 'anton.storchak', message: "pa_campaign_finance_download_csv EXCEPTION: #{e.backtrace}"
      p ('ERROR' * 10).colorize(:red)
      p e.to_s.colorize(:red)
      p e.backtrace.to_s.colorize(:red)
      exit 1
    end
    exit 0
  end
end
