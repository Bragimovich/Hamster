class BillGatesFoundationGrantsRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :woke_project])
  self.table_name = 'bill_gates_foundation_grants_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
