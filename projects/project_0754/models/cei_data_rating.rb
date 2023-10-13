class CeiDataRating < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'cei_data_rating'
  self.inheritance_column = :_type_disabled
end
