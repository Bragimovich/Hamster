
class IlLakeArrestees < ActiveRecord::Base
  self.table_name = 'il_lake__arrestees'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  validates_with IlValidateMd5Hash, on: :create, class_name: self
  before_create :add_md5
  strip_attributes
  has_many :addresses, class_name: "IlLakeArresteeAddresses", foreign_key: :arrestee_id
  has_many :arrests, class_name: "IlLakeArrests", foreign_key: :arrestee_id
  has_many :arrestee_ids, class_name: "IlLakeArresteeIds", foreign_key: :arrestee_id
  has_many :arrestee_aliase, class_name: "IlLakeArresteeAliases", foreign_key: :arrestee_id
  has_many :mugshots, class_name: "IlLakeMugshots", foreign_key: :arrestee_id
end
