# frozen_string_literal: true
class OhScCaseActivities < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  
  self.table_name = 'oh_sc_case_activities'
  self.inheritance_column = :_type_disabled
end

