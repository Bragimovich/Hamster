require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  DOMAIN = 'https://www.fdic.gov'

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
  end

  def download
    scraper = Scraper.new(keeper)
    inner_links = scraper.scrape_new_data
    inserted_links = keeper.fetch_db_inserted_links
    inner_links.each do |link|
      link = "https://www.fdic.gov#{link}"
      next if inserted_links.include? link
      scraper.scrape_inner_page(link)
    end
  end

  def download_archive
    scraper = Scraper.new(keeper)
    inserted_links = keeper.fetch_db_inserted_links
    ('2011'..'2019').each do |year|
      inner_links = scraper.scrape_archive_data(year)
      inner_links.each do |link|
        link = "https://www.fdic.gov/news/press-releases/#{year}/#{link}"
        next if inserted_links.include? link
        scraper.scrape_inner_page(link)
      end
    end
  end

  def store
    outer_page_files = get_outer_page_files
    outer_page_files.each do |file|
      outer_page = peon.give(subfolder: "#{keeper.run_id}_pages", file: file)
      links, dates, titles, releases = parser.get_data_json(outer_page)
      inserted_links = keeper.fetch_db_inserted_links
      links.each_with_index do |link, index|
        link = "https://www.fdic.gov#{link}"
        next if inserted_links.include? link
        get_html_page(link, dates[index], titles[index], releases[index])
      end
    end
    keeper.finish
  end

  def store_archive
    outer_page_files = get_outer_page_files
    outer_page_files.each do |file|
      year = file.scan(/\d+/).first
      outer_page = peon.give(subfolder: "#{keeper.run_id}_pages", file: file)
      links, dates, titles = parser.get_data_html(outer_page)
      inserted_links = keeper.fetch_db_inserted_links
      links.each_with_index do |link, index|
        link = "https://www.fdic.gov/news/press-releases/#{year}/#{link}"
        next if inserted_links.include? link
        get_html_page(link, dates[index], titles[index], nil, year)
      end
    end
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser

  def get_html_page(link, date, title, release = nil, year = nil)
    file_name = Digest::MD5.hexdigest link
    page = peon.give(subfolder: "#{keeper.run_id}_pages", file: file_name)
    data_hash = year == nil ? parser.get_article(page, link, date, title, release) : parser.get_article_html(page, link, date, title)
    keeper.save_record(data_hash)
  end

  def get_outer_page_files
    peon.give_list(subfolder: "#{keeper.run_id}_pages").select{|file| file.include? 'outer_page'}
  end
end
