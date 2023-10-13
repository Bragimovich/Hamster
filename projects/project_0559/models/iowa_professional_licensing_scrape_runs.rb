class IowaProfRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'iowa_professional_licensing_scrape_runs'
  self.inheritance_column = :_type_disabled
end
