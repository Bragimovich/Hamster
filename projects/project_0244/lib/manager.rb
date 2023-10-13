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
    @inserted_links = keeper.fetch_db_inserted_links
  end

  def download
    main_page = scraper.fetch_page
    save_file(main_page, "main_page", sub_folder)
    links, names = parser.fetch_csv_links(main_page.body)
    downloaded_files = peon.list(subfolder: sub_folder)
    links.each_with_index do |link, indx|
      file_name = parser.fetch_name(names[indx])
      next if inserted_links.include? link

      content = scraper.fetch_page(link)
      save_xlsx(content.body, file_name)
    end
  end
  
  def store
    hash_array = []
    main_page = peon.give(file: 'main_page.gz', subfolder: "#{sub_folder}")
    links, names = parser.fetch_csv_links(main_page)
    links.each_with_index do |link, indx|
      next if inserted_links.include? link

      file_name = parser.fetch_name(names[indx])
      path = "#{storehouse}store/#{sub_folder}/#{file_name}.csv"
      hash_array = parser.process_file(link, file_name, path, keeper.run_id)
      keeper.insert_records(hash_array)
    end
    keeper.finish
  end

  attr_accessor :keeper, :parser, :scraper, :sub_folder, :inserted_links

  def save_xlsx(content, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{sub_folder}"
    csv_storage_path = "#{storehouse}store/#{sub_folder}/#{file_name}.csv"
    File.open(csv_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def save_file(body, file_name, sub_folder)
    peon.put content: body.body, file: file_name, subfolder: sub_folder
  end
end
