class IrsNonProfitRuns < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :woke_project])

  self.table_name = 'irs_non_profit__runs'
end
