class CaseUnfetchedPdfs < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'ut_saac_case_unfetched_pdfs'
  self.inheritance_column = :_type_disabled
end
