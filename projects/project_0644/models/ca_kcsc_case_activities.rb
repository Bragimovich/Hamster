# frozen_string_literal: true
class CaKcscCaseActivities < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name         = 'ca_kcsc_case_activities'
  self.inheritance_column = :_type_disabled
end
