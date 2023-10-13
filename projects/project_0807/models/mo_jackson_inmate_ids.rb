class MoJacksonInmateID < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'mo_jackson_inmate_ids'
  self.inheritance_column = :_type_disabled
end
