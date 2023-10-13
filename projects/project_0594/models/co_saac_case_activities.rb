class CoSaacCaseActivity < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'co_saac_case_activities'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end