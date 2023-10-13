# frozen_string_literal: true
class TnSaacCaseRuns < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'tn_saac_case_runs'
end
