require_relative '../lib/parser'
require_relative '../lib/scraper'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper     = Keeper.new
    @parser     = Parser.new
    @scraper    = Scraper.new
    @sub_folder = "RunId_#{keeper.run_id}"
  end

  def download
    main_page = scraper.fetch_page
    save_file(main_page, "main_page", sub_folder)
    meta_links = parser.fetch_links(main_page.body)
    meta_links[0..2].each do |file_link|
      puts "Processing -->  #{file_link}".red
      response = scraper.fetch_page(file_link)
      already_downloaded_files = peon.list(subfolder: sub_folder)
      file_name = Digest::MD5.hexdigest "#{file_link}.gz"
      next if already_downloaded_files.include? file_name

      save_file(response, "#{file_name}", sub_folder)
      file_name, link = parser.xlsx_links(response.body)
      content = scraper.fetch_page(link)
      next if already_downloaded_files.include? "#{file_name}.xlsx"

      save_xlsx(content.body, file_name)
    end
  end

  def store
    main_page = peon.give(file: 'main_page.gz', subfolder: "#{sub_folder}")
    links = parser.fetch_links(main_page)
    links[0..2].each do |link|
      puts "File Name --> #{link}"
      file_name = Digest::MD5.hexdigest "#{link}.gz"
      response = peon.give(file: file_name, subfolder: "#{sub_folder}")
      file_name, link = parser.xlsx_links(response)
      path = "#{storehouse}store/#{sub_folder}/#{file_name}.xlsx"
      hash_array = parser.process_file(link, file_name, path, keeper.run_id)
      keeper.insert_records(hash_array)
    end
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper, :sub_folder

  def save_xlsx(content, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{sub_folder}"
    xlsx_storage_path = "#{storehouse}store/#{sub_folder}/#{file_name}.xlsx"
    File.open(xlsx_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def save_file(body, file_name, sub_folder)
    peon.put content: body.body, file: file_name, subfolder: sub_folder
  end
end
