# frozen_string_literal: true
class CaseParty < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'pa_ccpbc_case_party'
  self.inheritance_column = :_type_disabled
end
