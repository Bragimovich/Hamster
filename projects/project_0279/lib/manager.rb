require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @sub_folder = "Run_Id_#{@keeper.run_id}"
  end
  
  def run
    (keeper.download_status == "finish") ? store : download
  end

  private

  def download
    scraper  = Scraper.new
    scraper.get_file(storehouse, sub_folder)
    keeper.finish_download
    store
  end

  def store
    peon.list(subfolder: "#{sub_folder}").each do |file|
      page = "#{storehouse}store/#{sub_folder}/#{file}"
      if file.include?"demographic"
        hash_array, processed_md5 = parser.parse(page, keeper.run_id, file)
        keeper.save_records(hash_array, "offenders")
        keeper.update_touched_run_id(processed_md5, "offenders")
      elsif file.include?"booking"
        hash_array, processed_md5 = parser.parse(page, keeper.run_id, file)
        keeper.save_records(hash_array, "offenses")
        keeper.update_touched_run_id(processed_md5, "offenses")
      end
    end
    keeper.deleted("offenders")
    keeper.deleted("offenses")
    keeper.finish if (keeper.download_status == "finish")
  end

  attr_accessor :keeper, :parser, :sub_folder
end
