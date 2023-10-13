require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @links = []

  end

  def scrape
    download
    #store
  end

  def download
    ('a'..'z').each do |char| 
      url = "https://inmatesearch.wcsoma.org/?searchString1=&searchString2=#{char}&searchString3="
      page_response, status = @scraper.download_page(url)
      @links << @parser.get_links(page_response.body)
    end
    
    links = @links.flatten!
    inmate_id2 = 1
    arrest_id = 1
    links.each do |link|
      page_response, status = @scraper.download_page(link)
      inmate_data = @parser.get_inmate_detail(page_response.body, link)
      @keeper.store_inmate(inmate_data)
      inmate_data, inmate_id2 = @parser.get_inmate_num(page_response.body, link, inmate_id2)
      @keeper.store_inmate_ids(inmate_data)
      inmate_data, arrest_id = @parser.get_holdin_fac(page_response.body, link, arrest_id)
      @keeper.store_holding_fac(inmate_data)
    end
  end

  def store
    # write store logic here
  end
end
