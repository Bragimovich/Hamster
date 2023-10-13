require_relative '../lib/us_doj_ojp_scraper'
require_relative '../lib/us_doj_ojp_parser'
require_relative '../lib/us_doj_ojp_keeper'

class UsDojOjpManager < Hamster::Harvester
  DOMAIN = 'https://www.ojp.gov'
  
  def initialize(**params)
    super
    @keeper = UsDojOjpKeeper.new
    @parser = UsDojOjpParser.new
    @sub_folder = "RunId_#{@keeper.run_id}"
    @already_inserted_links = @keeper.fetch_db_inserted_links
    @already_downloaded_files = peon.give_list(subfolder: @sub_folder)
  end

  def download
    scraper = UsDojOjpScraper.new(keeper)
    outer_page = scraper.save_html_pages
    inner_links = parser.get_inner_links(outer_page)
    inner_links.each do |l|
      l = DOMAIN + l unless l.include? DOMAIN
      next if @already_inserted_links.include? l
      file_name = Digest::MD5.hexdigest l
      next if @already_downloaded_files.include? file_name + ".gz"
      scraper.process_inner_pages(l, file_name)
    end
  end

  def store
    run_id = keeper.run_id
    outer_page = peon.give(subfolder: @sub_folder, file: "outer_page.gz") 
    links, dates, titles = parser.get_data_html(outer_page)
    links.each_with_index do |l, index_no|
      l = DOMAIN + l
      next if (l.include? '.pdf') || (@already_inserted_links.include? l)
      get_html_page(l, dates[index_no], titles[index_no])
    end
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser

  def get_html_page(link, date, title)
   file_name = Digest::MD5.hexdigest link
   page = peon.give(subfolder:@sub_folder , file: file_name) rescue nil
   return if page.nil?
   data_hash = parser.get_article_html(page, link, date, title) 
   data_hash[:run_id] = keeper.run_id
   keeper.save_record(data_hash)
  end
end
