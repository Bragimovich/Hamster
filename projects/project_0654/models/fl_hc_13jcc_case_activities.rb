class FlCaseActivities < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'fl_hc_13jcc_case_activities'
  self.inheritance_column = :_type_disabled
end
