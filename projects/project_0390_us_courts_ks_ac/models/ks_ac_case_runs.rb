# frozen_string_literal: true

class KsAcCaseRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name         = 'ks_ac_case_runs'
  self.inheritance_column = :_type_disabled
  self.logger             = Logger.new(STDOUT)
end
