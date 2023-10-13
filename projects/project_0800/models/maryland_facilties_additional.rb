class MaryLandFacilitiesAdditional < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'maryland_holding_facilities_additional'
  self.inheritance_column = :_type_disabled
end
