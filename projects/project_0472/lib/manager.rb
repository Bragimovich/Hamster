require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  
  def initialize(**params)
    super
    @keeper     = Keeper.new
    @parser     = Parser.new
    @sub_folder = "RunId_#{@keeper.run_id}"
  end

  def download
    scraper = Scraper.new
    data    = scraper.scraper
    save_file(data, "lawyer-data")
  end

  def store
    html                     = peon.give(file:"lawyer-data", subfolder: @sub_folder)
    data_array               = parser.parser(html, keeper.run_id)
    md5_hashes_array         = data_array.map{|e| e[:md5_hash]}
    data_array.each_slice(10000){|e| keeper.save_record(e)}
    keeper.update_touched_run_id(md5_hashes_array)
    keeper.deleted
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser

  def save_file(html, file_name)
    peon.put content: html, file: file_name, subfolder: @sub_folder.to_s
  end
end
