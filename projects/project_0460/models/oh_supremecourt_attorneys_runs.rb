class OhSupremecourtAttorneysRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'oh_supremecourt_attorneys_runs'
  self.inheritance_column = :_type_disabled
end
