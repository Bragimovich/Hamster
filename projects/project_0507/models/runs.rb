class Runs < ActiveRecord::Base
  self.table_name = 'il_peoria__runs'
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])
end

