class NdDocMugshots < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])

  self.table_name = 'nd_doc_mugshots'
  self.inheritance_column = :_type_disabled
end
