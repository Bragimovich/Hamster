# frozen_string_literal: true
class FlCcsjcpcCaseActivity < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'fl_ccsjcpc_case_activities'
  self.inheritance_column = :_type_disabled
end
