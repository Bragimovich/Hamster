# frozen_string_literal: true
class UniversityOfPittsburghDirectoryRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
 
  self.table_name = 'university_of_pittsburgh_directory_runs'
  self.inheritance_column = :_type_disabled
end
