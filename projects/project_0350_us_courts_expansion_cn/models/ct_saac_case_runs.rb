# frozen_string_literal: true

# require_relative '../config/database_config'

class CtSaacCaseRuns < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary

  self.table_name = 'ct_saac_case_runs'
  self.logger = Logger.new(STDOUT)
end
