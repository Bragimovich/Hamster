class GeneralAssemblyRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name         = 'tx_general_assembly_runs'
  self.inheritance_column = :_type_disabled
end
