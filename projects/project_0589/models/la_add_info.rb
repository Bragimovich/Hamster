# frozen_string_literal: true
class LaAddInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'la_2c_ac_case_additional_info'
  self.inheritance_column = :_type_disabled
end
