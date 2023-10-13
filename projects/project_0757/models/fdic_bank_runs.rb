class FdicBankRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'fdic_bank_runs'
  self.inheritance_column = :_type_disabled
end
