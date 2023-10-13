class IaCaseInfoAdd < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'ia_sc_case_additional_info'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end