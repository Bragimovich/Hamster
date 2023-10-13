class Hearings < ActiveRecord::Base
  self.table_name = 'il_kendall__court_hearings'
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])
end

