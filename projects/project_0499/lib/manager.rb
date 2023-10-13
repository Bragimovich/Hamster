# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/keeper'
require_relative '../../../lib/ashman/ashman.rb'

LATEST = "https://data.cityofchicago.org/api/views/dpt3-jri9/rows.csv?accessType=DOWNLOAD"

class CityOfChicagoManager < Hamster::Harvester
  def download
    @csv_file = Scraper.new.download_csv(LATEST)
  end

  def store
    @csv_file ||= Dir[Scraper.new.storehouse + "store/*"].sort[-1]
    Keeper.new.store_to_db(@csv_file)
    Scraper.new.clear
  end

  def test
    ashman = Hamster::Ashman.new({:aws_opts => {}, account: :loki, bucket: 'loki-files'})
    list = ashman.list({prefix: 'tasks/scrape_tasks/st00499/'})
    filenames = list[:contents].map {|el| list.name + "/" + el.key}
    filenames.each {|line| logger.info(line)}
  end
end
