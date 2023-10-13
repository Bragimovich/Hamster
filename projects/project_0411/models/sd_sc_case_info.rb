# frozen_string_literal: true
class TableInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'sd_sc_case_info'
  self.inheritance_column = :_type_disabled
end
