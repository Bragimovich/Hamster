
class IlLakeCharges < ActiveRecord::Base
  self.table_name = 'il_lake__charges'
  include Hamster::Granary
  include ModelsHelpers
  strip_attributes
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  validates_with IlValidateMd5Hash, on: :create, class_name: self
  before_create :add_md5
  has_many :charge, class_name: "IlLakeCharges", foreign_key: :charge_id
  has_many :court_hearing, class_name: "IlLakeCourtHearing", foreign_key: :charge_id
end
