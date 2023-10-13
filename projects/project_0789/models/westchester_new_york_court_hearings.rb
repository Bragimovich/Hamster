class WestchesterNewYorkCourtHearings < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'westchester_new_york_court_hearings'
  self.inheritance_column = :_type_disabled
end
