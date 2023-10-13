require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
  end

  def run_script
    (keeper.download_status == "finish") ? store : download
  end

  def download
    scraper = Scraper.new
    json_api_response = scraper.api_request
    xlsx_url = parser.get_xlsx_link(json_api_response.body)
    xlsx_response = scraper.xlsx_request(xlsx_url)
    save_xlxs(xlsx_response.body, "file")
    keeper.finish_download
    store
  end

  def store
    folder =  peon.list(subfolder: "#{keeper.run_id}")
    file = (folder[0].include? ".~lock") ?  folder[1] : folder[0]
    file_path = "#{storehouse}store/#{keeper.run_id}/#{file}"
    salaries_data_array = parser.get_data(file_path, "#{keeper.run_id}")
    md5_array = salaries_data_array.map{|e| e[:md5_hash]}
    keeper.update_touched_run_id(md5_array)
    keeper.insert_data(salaries_data_array)
    if (keeper.download_status == "finish")
      keeper.mark_deleted
      keeper.finish
    end
  end

  private

  attr_accessor :parser, :keeper

  def save_xlxs(content, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}"
    zip_storage_path = "#{storehouse}store/#{keeper.run_id}/#{file_name}.xlsx"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end

end
