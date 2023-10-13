# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
  end

  def scrape
    scraper = Scraper.new
    data = []
    saved_pdf_urls = @keeper.saved_pdf_urls
    scraper.scrape do |pdf_url_data|
      next unless pdf_url_data[:url].include?('.pdf')
      next if saved_pdf_urls.include?(pdf_url_data[:url])

      data = @parser.process_pdf(pdf_url_data)
      data.each do |hash|
        @keeper.insert_record(hash)
      end
      logger.debug("Scraped : #{pdf_url_data[:url]}")
    end
    # We don't need to call this method because we are adding PDF data when added new PDF file attached to the page
    # @keeper.update_history
    @keeper.finish
  end
end
