class FlCaseRelationActivityPdf < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'fl_hc_13jcc_case_relations_activity_pdf'
  self.inheritance_column = :_type_disabled
end
