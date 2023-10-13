class TexasRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'texas_runs'
  self.inheritance_column = :_type_disabled
end
