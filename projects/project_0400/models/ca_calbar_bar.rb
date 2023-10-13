class CACB < ActiveRecord::Base
  self.table_name = 'ca_calbar_bar'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end

