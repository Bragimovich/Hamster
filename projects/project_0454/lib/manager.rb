# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/keeper'

LATEST = "https://raw.githubusercontent.com/globaldothealth/monkeypox/main/latest.csv"

class GlobalDotHealthManager < Hamster::Harvester

  def download
    @csv_file = Scraper.new.download_csv(LATEST)
  end

  def store
    @csv_file = Dir[Scraper.new.storehouse + "store/*"].sort[-1] if !@csv_file
    Keeper.new.store_to_db(@csv_file)
  end

end
