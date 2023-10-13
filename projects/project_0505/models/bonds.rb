class Bonds < ActiveRecord::Base
  self.table_name = 'il_champaign__bonds'
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])
end

