class MAACRelations < ActiveRecord::Base
  self.table_name = 'maac_case_relations_activity_pdf'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

