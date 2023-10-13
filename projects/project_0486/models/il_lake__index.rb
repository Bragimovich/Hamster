

class IlLakeIndex < ActiveRecord::Base
  include ModelsHelpers
  include Hamster::Granary
  strip_attributes
  self.table_name = 'il_lake__index'
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])

end
