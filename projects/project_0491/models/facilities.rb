class Facilities < ActiveRecord::Base
  self.table_name = 'il_macon__holding_facilities'
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])
end

