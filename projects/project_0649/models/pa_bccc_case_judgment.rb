# frozen_string_literal: true

class PaBcccCaseJudgment < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name         = 'pa_bccc_case_judgment'
  self.inheritance_column = :_type_disabled
end
