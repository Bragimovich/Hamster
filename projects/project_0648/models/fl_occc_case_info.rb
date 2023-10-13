# frozen_string_literal: true

class FlOcccCaseInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'fl_occc_case_info'
  self.inheritance_column = :_type_disabled
end
