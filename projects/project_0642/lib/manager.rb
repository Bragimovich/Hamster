require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  attr_reader :keeper
  
  def initialize(**params)
    super
    @keeper  = Keeper.new
    @scraper = Scraper.new
    @parser  = Parser.new
  end

  def scrape
    Hamster.report(to: 'U02JPKC1KSN', message: "0642 Download Started")
    @scraper.download_csv "https://www.iacourtcommissions.org/ords/f?p=106:1:112774553283634:::::"

    Hamster.report(to: 'U02JPKC1KSN', message: "0642 Download Finish\nStart store")

    csv_path = Dir.glob("#{storehouse}*").find{ |x| x.match? /.csv$/ }
    @parser.read_csv(csv_path)
    @parser.process_data { |data_hash| keeper.store_data(data_hash) }

    keeper.update_delete_status
    keeper.finish
    File.delete(csv_path) if File.exist?(csv_path)
    Hamster.report(to: 'U02JPKC1KSN', message: "0642 Store Finished")
  end
end
