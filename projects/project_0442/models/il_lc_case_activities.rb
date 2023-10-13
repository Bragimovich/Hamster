class IlLcCaseActivities < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary
  
  self.table_name = 'il_lc_case_activities'
  self.logger = Logger.new(STDOUT)
end
