
class IlLakeMugshots < ActiveRecord::Base
  self.table_name = 'il_lake__mugshots'
  include Hamster::Granary
  include ModelsHelpers
  strip_attributes
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  validates_with IlValidateMd5Hash, on: :create, class_name: self
  before_create :add_md5
end
