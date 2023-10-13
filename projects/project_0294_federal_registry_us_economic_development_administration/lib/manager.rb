require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester
  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
  end

  def download
    url = "https://www.eda.gov/news?f%5B0%5D=type%3APress%20Release"
    main_page = scraper.connect_to(url)
    save_file("#{keeper.run_id}", main_page.body, "main_page")
    inner_links = parser.inner_links(main_page.body)
    links_data = inner_links_data(inner_links)
  end

  def store
    already_processed = keeper.fetch_db_inserted_links
    main_page = peon.give(subfolder: "#{keeper.run_id}", file: "main_page")
    inner_links = parser.inner_links(main_page)
    links_data = link_data(inner_links,already_processed)
    main_page_tags = parser.tags(main_page)
    keeper.insert_tags(main_page_tags)
    keeper.finish
  end

  private
  attr_accessor :keeper, :parser, :scraper

  def link_data(links,already_processed)
    links.each do |link|
      next if already_processed.include? link
      file_name = Digest::MD5.hexdigest link
      link_file = peon.give(subfolder: "#{keeper.run_id}/Inner_links", file: "#{file_name}")
      link_hash = parser.link_data(link,link_file,"#{keeper.run_id}")
      keeper.insert_record(link_hash)
    end
  end

  def inner_links_data(inner_links)
    inner_links.each do |link|
      link_data = scraper.connect_to(link)
      file_name  = Digest::MD5.hexdigest link
      save_file("#{keeper.run_id}/Inner_links", link_data.body, file_name)
    end
  end

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end

end
