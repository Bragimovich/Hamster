# frozen_string_literal: true

class FootballConference < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :us_sports_ihsa_raw])
  self.table_name = 'football__conferences'
  self.inheritance_column = :_type_disabled
end
