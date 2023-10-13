# frozen_string_literal: true
class CaseRelationsInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'pa_ccpbc_case_relations_info_pdf'
  self.inheritance_column = :_type_disabled
end
