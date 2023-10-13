# frozen_string_literal: true
class MaineCourts < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :crime_inmate])
    self.table_name = 'maine_court_hearings'
    self.inheritance_column = :_type_disabled
end
