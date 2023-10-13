# frozen_string_literal: true
class CaseInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'pa_ccpbc_case_info'
  self.inheritance_column = :_type_disabled
end
