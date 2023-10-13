class CasePdfRelations < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'ut_saac_case_relations_info_pdf'
  self.inheritance_column = :_type_disabled
end
