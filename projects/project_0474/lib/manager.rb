
# frozen_string_literal: true

require_relative '../lib/parser'
require_relative '../lib/scraper'
require_relative '../lib/keeper'

CSV_URL = "https://data.ny.gov/api/views/eqw2-r5nb/rows.csv?accessType=DOWNLOAD&sorting=true"

class Manager < Hamster::Harvester
  def download
    Scraper.new.download_csv
    Parser.new.run_csv
  end

  def store
    keeper = Keeper.new
    keeper.run_sql
    keeper.update_run_id
    Scraper.new.clear
    keeper.finish
  end    
end
