class EADA < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'eada_equity_in_athletic'
  self.inheritance_column = :_type_disabled
end
