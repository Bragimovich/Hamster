# frozen_string_literal: true
class WaSaacCaseInfoRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'wa_saac_case_info_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
