class HsAthlete < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :limparanoia])
  include Hamster::Granary

  self.table_name = 'hs_athlete_twitter_announcements'
end
