require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper                   = Keeper.new
    @parser                   = Parser.new
    @sub_folder               = "RunId_#{keeper.run_id}"
  end

  def download
    scraper     = Scraper.new
    district_response = scraper.district_file
    school_response = scraper.school_file
    save_file(district_response.body, 'district')
    save_file(school_response.body, 'school')
  end

  def store
    all_files = Dir["#{storehouse}store/#{sub_folder}/*.xlsx"]
    all_files.each do |file|
      record_type = file.split('/').last.gsub('.xlsx','')
      db_md5 = keeper.fetch_db_md5(record_type)
      hash_array, update_array = parser.process_file(keeper.run_id, file, db_md5)
      keeper.save_record(hash_array, record_type)
      keeper.update_touch_run_id(update_array, record_type)
      keeper.mark_deleted(record_type)
    end
    keeper.finish
  end

  private

  def save_file(response, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{sub_folder}"
    zip_storage_path = "#{storehouse}store/#{sub_folder}/#{file_name}.xlsx"
    File.open(zip_storage_path, "wb") do |f|
      f.write(response)
    end
  end
  attr_accessor :keeper, :parser, :sub_folder
end
