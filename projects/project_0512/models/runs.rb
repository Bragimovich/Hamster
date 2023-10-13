class Runs < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_perps__step_1])
  self.table_name = 'police_departments_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end