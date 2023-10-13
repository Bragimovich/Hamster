
class IlLakeArrests < ActiveRecord::Base
  self.table_name = 'il_lake__arrests'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  validates_with IlValidateMd5Hash, on: :create, class_name: self
  after_validation :after_validation_toucher_run_id
  before_create :add_md5
  strip_attributes

  belongs_to :run_id, class_name: "IlLakeRuns", foreign_key: :run_id
  has_many :bonds, class_name: "IlLakeBonds", foreign_key: :arrest_id
  has_many :charges, class_name: "IlLakeCharges", foreign_key: :arrest_id
  has_many :holding_facilities, class_name: "IlLakeHoldingFacilities", foreign_key: :arrest_id

end
