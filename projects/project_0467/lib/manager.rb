require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @sub_folder = "RunId_#{@keeper.run_id}"
    @already_inserted_links = @keeper.fetch_db_inserted_links
  end

  def download
    scraper = Scraper.new()
    date = "#{Date.today.year}/#{Date.today.month}"
    outer_page = scraper.main_page("https://news.maryland.gov/dhcd/#{date}/")
    save_file(outer_page,"outer_page")
    links = parser.get_links(outer_page.body)
    links.each do |link|
      next if @already_inserted_links.include? link
      inner_page = scraper.main_page(link)
      file_name = Digest::MD5.hexdigest link
      save_file(inner_page,file_name)
    end
  end

  def store
    outer_page = peon.give(file: "outer_page", subfolder: @sub_folder) rescue nil
    return if outer_page.nil?

    links = parser.get_links(outer_page)
    dates = parser.get_dates(outer_page)
    data_array = []
    links.each_with_index do |link,index|
      next if @already_inserted_links.include? link
      file_name = Digest::MD5.hexdigest link
      html = peon.give(file:file_name, subfolder: @sub_folder) rescue nil
      next if html.nil?

      data_hash = parser.parser(html, link, keeper.run_id,dates[index])
      data_array << data_hash
    end
    keeper.save_record(data_array) unless (data_array.empty?)
    keeper.finish
  end
  
  private

  attr_accessor :keeper, :parser

  def save_file(html, file_name)
    peon.put content: html.body, file: file_name, subfolder: @sub_folder
  end
end
