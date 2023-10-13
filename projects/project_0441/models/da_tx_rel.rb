class DATXRelations < ActiveRecord::Base
  self.table_name = 'da_tx_case_relations_activity_pdf'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

