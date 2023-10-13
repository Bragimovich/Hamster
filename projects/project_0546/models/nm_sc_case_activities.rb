# frozen_string_literal: true

class NmScCaseActivities < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary

  self.table_name = 'nm_saac_case_activities'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
