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
    main_page_request = scraper.main_page
    main_page_body = parser.main_page_body(main_page_request)
    tab_links = parser.all_tabs_link(main_page_body)
    page_links_array = main_pages(tab_links)
    page_links_array.each do |csv_page|
      csv_page_data = scraper.link_connect_inner(csv_page)
      file_name = csv_page.split('/').last
      save_file("#{keeper.run_id}/csv_pages",csv_page_data.body,file_name)
      csv_links = parser.each_csv_link_data(csv_page_data.body)
      csvs = csv_links.flatten
      csvs_downloading(csvs)
    end
  end

  def store
    inserted_records = keeper.fetch_db_inserted_md5_hash
    main_pages = peon.give_list(subfolder: "#{keeper.run_id}/csv_pages")
    csv_links_array = get_csv_link(main_pages)
    csv_links_array.each do |page|
      page_link = page.split('/').last
      file = Dir["#{storehouse}store/#{keeper.run_id}/#{page_link}"]
      csv_data_array = parser.parsing_csv(file, "#{keeper.run_id}",page, inserted_records)
      unless csv_data_array.empty?
        csv_data_array.count < 5000 ? keeper.insert_records(csv_data_array) : csv_data_array.each_slice(5000){|data| keeper.insert_records(data)}
      end
    end
    keeper.finish
  end

  private
  attr_accessor :keeper, :parser, :scraper

  def csvs_downloading(csvs)
    csvs.each do |csv|
      file_name = csv.split('/').last
      scraper.csv_downloading(csv, "#{keeper.run_id}" , "#{file_name}")
    end
  end

  def main_pages(tab_links)
    page_links_array = []
    tab_links.each do |tab_link|
      tab_scraped_page = scraper.link_connect(tab_link)
      page_links_array << parser.tab_page_link(tab_scraped_page.body)
    end
    page_links_array.flatten
  end

  def get_csv_link(main_pages)
    csv_links_array = []
    main_pages.each do |links|
      csv_page_data = peon.give(subfolder: "#{keeper.run_id}/csv_pages", file: links)
      csv_links_array << parser.each_csv_link_data(csv_page_data)
    end
    csv_links_array.flatten
  end

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end

end
