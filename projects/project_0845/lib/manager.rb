require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def scrape(options)
    if options[:range]
      st, ed = options[:range].split('-')
      letters = st..ed
    else
      letters = 'a'..'z'
    end
    letters = [options[:letter]] if options[:letter]

    logger.info "scraping with letters: #{letters}"
    letters.each do |letter|
      retry_count = 0
      response = @scraper.search(letter)
      page = 1
      loop do
        logger.info "letter: #{letter}, page: #{page}"
        begin
          response = @scraper.scrape_per_page(letter, page)
          inmate_data = @parser.inmate_ids(response.body)
          store(inmate_data)

          break if inmate_data.count < 200
        rescue DetailPageTokenExpired => e
          next if retry_count > 3

          logger.info "expired detail page and token"
          response = @scraper.search(letter)

          retry_count += 1
          retry
        end
        page += 1
      end
    end
    @keeper.regenerate_and_flush
    @keeper.update_history
    @keeper.finish
  end

  def store(inmate_data)
    inmate_data.each do |data|
      store_to_db(data)
    end
  end

  def clear
    @keeper.regenerate_and_flush
  end

  private
  
  class DetailPageTokenExpired < StandardError; end

  def store_to_db(data)
    detail_page_url = "#{Scraper::HOST}#{data[:href]}"
    response = @scraper.detail_page(detail_page_url)

    raise DetailPageTokenExpired unless response
    
    data_source_url = "#{Scraper::HOST}/ArrestInquiry/Home/ViewArrest?id=#{data[:booking_number]}"
    hash_data = @parser.parse_detail_page(response.body, data_source_url, @scraper, data)
    @keeper.store(hash_data)
  end
end
