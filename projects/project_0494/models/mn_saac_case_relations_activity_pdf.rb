class MnSaacCaseRelations < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'mn_saac_case_relations_activity_pdf'
  self.inheritance_column = :_type_disabled
end
