class Arrestees < ActiveRecord::Base
  self.table_name = 'il_kendall__arrestees'
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])
end

