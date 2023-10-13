require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def scrape(options)
    letter_range = options[:block] == 'first' ? ('a'..'k') : ('l'..'z')
    letter_range = [options[:letter]] if options[:letter]
    letter_range.each do |letter|
      logger.info("Started --- last_name is #{letter}")
      response = @scraper.scrape(letter)
      @parser.get_detail_page_links_from(response.body).each do |detail_page_url|
        store(detail_page_url)
      end
      logger.info("Stored results: last_name is #{letter}")
    end
    @keeper.regenerate_and_flush
    @keeper.update_history
    @keeper.finish
  end

  def store(url)
    retry_count     = 0
    detail_page_url = "#{Scraper::BASE_URL}/mdoc/inmate/Search/#{url}"
    begin
      response = @scraper.scrape_detail_page(detail_page_url)

      raise NotFoundContent unless @parser.parseable?(response.body)

      hash_data = @parser.parse_detail_page(response.body, detail_page_url, @scraper)
      @keeper.store(hash_data)
    rescue => e
      logger.info '----------------not found inmate-------------'
      logger.info detail_page_url
      logger.info e.full_message

      return if retry_count > 2

      sleep 60 * 3
      retry_count += 1
      retry
    end
  end

  def clear
    @keeper.regenerate_and_flush
  end

  private

  class NotFoundContent < StandardError; end
end
