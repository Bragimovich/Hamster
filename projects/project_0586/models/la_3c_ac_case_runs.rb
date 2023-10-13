# frozen_string_literal: true

class La3cAcCaseRuns < ActiveRecord::Base
  self.table_name = 'la_3c_ac_case_runs'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.inheritance_column = :_type_disabled
end
