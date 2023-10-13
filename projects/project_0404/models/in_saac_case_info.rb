class InSaacCaseInfo < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary

  self.table_name = 'in_saac_case_info'
  self.logger = Logger.new(STDOUT)
end