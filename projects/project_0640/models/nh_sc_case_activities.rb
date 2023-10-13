class NhScCaseActivities < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'nh_sc_case_activities'
  self.inheritance_column = :_type_disabled
end
