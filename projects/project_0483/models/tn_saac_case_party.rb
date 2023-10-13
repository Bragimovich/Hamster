# frozen_string_literal: true
class TnSaacCaseParty < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name         = 'tn_saac_case_party'
  self.inheritance_column = :_type_disabled
end
