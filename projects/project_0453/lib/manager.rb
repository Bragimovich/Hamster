# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

HEADERS = {
  accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  accept_language:           'en-US,en;q=0.5',
  connection:                'keep-alive',
  upgrade_insecure_requests: '1'
}
PAGE = "https://app.powerbigov.us/view?r=eyJrIjoiMmE2MTExYTYtNDA2Ny00NzNlLThlNzUtYmM0YWYzMzk0MjlhIiwidCI6IjljZTcwODY5LTYwZGItNDRmZC1hYmU4LWQyNzY3MDc3ZmM4ZiJ9&amp;pageName=ReportSectionccb549e3876377a06521"
DAY = 86400

class PowerBI < Hamster::Harvester

  def download
    @pdf_data = Scraper.new.scrape
  end

  def parse
    @cases_data = Parser.new.parse
  end

  def store
    Keeper.new.store_pdf(@pdf_data)
    Keeper.new.store_cases(@cases_data)
  end

end
