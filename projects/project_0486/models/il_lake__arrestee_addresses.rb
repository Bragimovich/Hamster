
class IlLakeArresteeAddresses < ActiveRecord::Base
  self.table_name = 'il_lake__arrestee_addresses'
  include Hamster::Granary
  include ModelsHelpers
  strip_attributes
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  validates_with IlValidateMd5Hash, on: :create, class_name: self
  after_validation :after_validation_toucher_run_id
  before_create :add_md5
end
