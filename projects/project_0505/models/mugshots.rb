class Mugshots < ActiveRecord::Base
  self.table_name = 'il_champaign__mugshots'
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])
end

