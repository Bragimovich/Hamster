require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end  

  def process_store
    process_store_data
    @keeper.finish
  rescue Exception => e
    logger.info(e.full_message)
    Hamster.report(to: 'Mashal Ahmad', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
  end  
  
  def process_store_data
    md5_array = []
    outer_link = "https://transparentcalifornia.com/agencies/salaries/#university-system"
    outer_page_response , status = @scraper.download_page(outer_link)          
    links =  @parser.get_outerpage_links(outer_page_response.body)
    links.each do |link|
      page_response, status = @scraper.download_page(link)
      pages = @parser.check_pagination(page_response.body)
      if pages
       pages = pages.delete(',').to_i
       page = 1
       max_page = pages > 50 ? 50 : pages
       while page <= max_page 
        url = link + "?page=#{page}"
        page_response, status = @scraper.download_page(url)
        hashes = @parser.parse_maintable(page_response.body, url)
        @keeper.store_ca_ed_salaries(hashes)
        md5_array << hashes.map { |hash| hash["md5_hash"] }
        page += 1
       end
       @keeper.update_touch_run_id(md5_array)
      else 
       hashes = @parser.parse_maintable(page_response.body,link)
       hashes ? @keeper.store_ca_ed_salaries(hashes) : logger.info("No records found") 
       md5_array << hashes.map { |hash| hash["md5_hash"] }
       @keeper.update_touch_run_id(md5_array)
      end
    end
  end
end