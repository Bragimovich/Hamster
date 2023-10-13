# frozen_string_literal: true

class CaliforniaFresnoRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01 , db: :crime_inmate])
  self.table_name = 'california_fresno_runs'
  self.inheritance_column = :_type_disabled
end
