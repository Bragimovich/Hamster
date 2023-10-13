# frozen_string_literal: true

class RawNjScCaseAdditionalInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])

  self.table_name = 'nj_sc_case_additional_info'
  self.inheritance_column = :_type_disabled
end
