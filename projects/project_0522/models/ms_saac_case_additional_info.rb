# frozen_string_literal: true

class MsSaacCaseAdditionalInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary

  self.table_name = 'ms_saac_case_additional_info'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end