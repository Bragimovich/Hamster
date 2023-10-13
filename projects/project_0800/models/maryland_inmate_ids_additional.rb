class MaryLandInmateIdsAdditional < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'maryland_inmate_ids_additional'
  self.inheritance_column = :_type_disabled
end
