class PbRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'pb_runs'
  self.inheritance_column = :_type_disabled
end
