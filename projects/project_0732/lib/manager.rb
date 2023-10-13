# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

URL = "https://www.arcgis.com/sharing/rest/content/items/05fc56e59c8b45d2bda47551ef305743/data?f=json"

class UsSheriffsManager < Hamster::Harvester
  def download
    @us_sheriffs_info = Parser.new.parse(Scraper.new.get_source(URL))
  end

  def store
    Keeper.new.store_to_db(@us_sheriffs_info)
  end
end
