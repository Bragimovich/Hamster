# frozen_string_literal: true
class MoJudge < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'md_dccc_case_judgment'
  self.inheritance_column = :_type_disabled
end
