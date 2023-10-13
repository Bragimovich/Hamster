class VtScCaseRelationsActivityPdf < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'vt_sc_case_relations_activity_pdf'
end
