require_relative '../models/raw_tx__harris_county_texas_sheriff_office_immates'
class Keeper
  def store(arrests)
    arrests.each {|arrest| RawTxHarrisCountyTexasSheriffOfficeImmates.store(arrest)}
  end
end
