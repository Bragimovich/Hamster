

class IlLakeCountySheriffIndex < ActiveRecord::Base

  self.table_name = 'il_lake_county_sheriff_index'
  establish_connection(Storage[host: :db11, db: :usa_raw])

end
