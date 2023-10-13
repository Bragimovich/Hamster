class MtBarMontanabarOrg < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'mt_bar_montanabar_org'
  self.inheritance_column = :_type_disabled
end
