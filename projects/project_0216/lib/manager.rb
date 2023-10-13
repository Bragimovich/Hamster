require_relative '../lib/parser'
require_relative '../lib/scraper'
require_relative '../lib/keeper'
require 'zip'

class Manager < Hamster::Harvester
  MAIN_URL = "https://www.ffiec.gov/craratings/Rtg_spec.html"

  def initialize(**params)
    super
    @keeper     = Keeper.new
    @parser     = Parser.new
    @scraper    = Scraper.new
  end

  def download
    main_page = scraper.fetch_page(MAIN_URL)
    link = parser.fetch_file_link(main_page.body)
    process_zip_entities(link)
  end

  def store
    inserted_records = keeper.fetch_db_inserted_md5_hash
    file_path = "#{storehouse}store/#{keeper.run_id}"
    file_name = access_file_name(file_path)
    content = unzip_file("#{file_path}/#{file_name}")
    hash_array = parser.process_file(content, keeper.run_id, inserted_records)
    keeper.insert_records(hash_array) unless hash_array.empty?
    keeper.finish
  end

  attr_accessor :keeper, :parser, :scraper

  private

  def unzip_file(file_name)
    content = nil
    zip_file = Zip::File.open("#{file_name}")
    zip_file.first.get_input_stream { |io|
      content = io.read
    }
    content
  end

  def access_file_name(file_path)
    file = Dir.entries("#{file_path}").select { |f| File.file? File.join("#{file_path}", f) }
    file.select{ |f| f.end_with? "zip" }.first
  end

  def process_zip_entities(link)
    response = scraper.fetch_page(link)
    save_zip(response.body,"#{keeper.run_id}","data")
  end

  def save_zip(content, sub_folder, name)
    FileUtils.mkdir_p "#{storehouse}store/#{sub_folder}/"
    zip_storage_path = "#{storehouse}store/#{sub_folder}/#{name}.zip"
    File.open(zip_storage_path, 'wb') do |f|
      f.write(content)
    end
  end

end
