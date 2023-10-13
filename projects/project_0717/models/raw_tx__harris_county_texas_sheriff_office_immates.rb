class RawTxHarrisCountyTexasSheriffOfficeImmates < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :foia_inmate_gather])
  include Hamster::Granary

  self.table_name = 'raw_tx__harris_county_texas_sheriff_office_immates'
end
