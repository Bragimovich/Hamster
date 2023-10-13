require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper                   = Keeper.new
    @parser                   = Parser.new
    @sub_folder               = "RunId_#{@keeper.run_id}"
    @already_inserted_links   = @keeper.fetch_db_inserted_links
    @already_downloaded_files = peon.give_list(subfolder: @sub_folder)
  end

  def download
    scraper     = Scraper.new(keeper)
    total_pages = 10
    (0..total_pages).each do |page|
      outer_page = scraper.scraper(page)
      save_file(outer_page, "outer_#{page}")
      links = parser.get_links(outer_page)
      links.each do |link|
        next if @already_inserted_links.include? link

        inner_page = scraper.download_inner_pages(link)
        file_name  = Digest::MD5.hexdigest link
        next if @already_downloaded_files.include? file_name + '.gz'

        save_file(inner_page, file_name)
      end
    end
  end

  def store
    run_id      = keeper.run_id
    pages       = peon.give_list(subfolder: @sub_folder)
    outer_pages = pages.reject { |e| e.exclude? 'outer' }.sort
    outer_pages.each do |outer_page|
      html  = peon.give(file: outer_page, subfolder: @sub_folder)
      links = parser.get_links(html)
      links.each do |link|
        next if @already_inserted_links.include? link
        file_name = Digest::MD5.hexdigest link
        file_name = file_name + '.gz'
        html      = peon.give(file: file_name, subfolder: @sub_folder)
        data_hash = parser.parser(html, link, run_id)
        keeper.save_record(data_hash)
      end
    end
    keeper.finish
  end

  private

  def save_file(html, file_name)
    peon.put content: html, file: file_name, subfolder: @sub_folder
  end

  attr_accessor :keeper, :parser
end
