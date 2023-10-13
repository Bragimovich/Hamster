require_relative '../lib/keeper'
require_relative '../lib/scraper'
require_relative '../lib/parser'
require 'zip'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper     = Keeper.new
    @parser     = Parser.new
  end

  def download
    scraper  = Scraper.new
    page     = scraper.connect_main
    save_zip(page.body,'all_year_data','zip_file')
  end

  def store
    zip_file   = "#{storehouse}store/zip_file/all_year_data.zip"
    text_file  = unzip_file(zip_file)
    hash_array = []
    text_file.each_line.each_with_index do |line, index|
      next if index == 0
      hash_array << parser.parse_row(line.chomp, keeper.run_id)
      if hash_array.count > 4999
        keeper.insert_records(hash_array)
        hash_array = []
      end
    end
    keeper.insert_records(hash_array) unless hash_array.empty?
    keeper.finish
  end
  private

  attr_accessor  :parser ,:keeper 

  def save_zip(content, file_name, sub_folder)
    FileUtils.mkdir_p "#{storehouse}store/#{sub_folder}"
    zip_storage_path = "#{storehouse}store/#{sub_folder}/#{file_name}.zip"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def unzip_file(file_name)
    content = nil
    zip_file = Zip::File.open(file_name)
    zip_file.first.get_input_stream { |io|
      content = io.read
    }
    content
  end

end
