class CraRatingsRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db13, db: 'usa_raw'])	
  self.table_name = 'cra_ratings_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
