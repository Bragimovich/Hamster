# frozen_string_literal: true

class MdAcCaseRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'md_ac_case_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new($stdout)
end
  