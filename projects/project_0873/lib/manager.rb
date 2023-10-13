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
    letters = letter_range(options)
    letters.each do |letter|
      county_list.each do |county|
        begin
          logger.debug "Scraping with letter: #{letter}, county: #{county}"
          inmate_list = @scraper.search(letter, county)
          store(inmate_list)
        rescue => e
          logger.info "Raised and next in Manager#scrape with letter: #{letter}, county: #{county}"
          logger.info e.full_message
          next
        end
      end
    end
  end

  def store(inmate_list)
    inmate_list.each do |href|
      retry_count = 0
      detail_page_url = Scraper::HOST + href
      begin
        response_body   = @scraper.detail_page(detail_page_url)
        hash_data       = @parser.parse_detail_page(response_body, detail_page_url)
        @keeper.store(hash_data)
      rescue => e        
        if retry_count > 3
          logger.debug "#{'>'*15} #{detail_page_url}"
          logger.debug response_body
          logger.debug e.full_message

          next
        end

        @scraper.accept_terms!
        retry_count += 1

        retry
      end
    end
  end

  def clear
    @keeper.regenerate_and_flush
  end

  private

  def letter_range(options)
    if options[:letter]
      [options[:letter]]
    elsif options[:range]
      st, ed = options[:range].split('-')
      st..ed
    else
      'a'..'z'
    end
  end

  def county_list
    [
      'ATLANTIC',
      'BERGEN',
      'BURLINGTON',
      'CAMDEN',
      'CAPE MAY',
      'CUMBERLAND',
      'ESSEX',
      'GLOUCESTER',
      'HUDSON',
      'HUNTERDON',
      'IMMIGRATION & NATURALIZATION SERVICES',
      'MERCER',
      'MIDDLESEX',
      'MONMOUTH',
      'MORRIS',
      'NOT APPLICABLE',
      'OCEAN',
      'OUT-OF-STATE COURT',
      'PASSAIC',
      'SALEM',
      'SOMERSET',
      'SUSSEX',
      'UNION',
      'US DISTRICT COURT CAMDEN',
      'WARREN'
    ]
  end
end
