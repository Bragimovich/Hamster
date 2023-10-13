# frozen_string_literal: true
class GaAcCaseParty < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'ga_ac_case_party'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
