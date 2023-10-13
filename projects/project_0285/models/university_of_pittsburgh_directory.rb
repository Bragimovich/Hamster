# frozen_string_literal: true
class UniversityOfPittsburghDirectory < ActiveRecord::Base
  self.table_name = 'university_of_pittsburgh_directory'
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.inheritance_column = :_type_disabled
end
