class Messages < ActiveRecord::Base
  self.table_name = 'alerts_messages'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
