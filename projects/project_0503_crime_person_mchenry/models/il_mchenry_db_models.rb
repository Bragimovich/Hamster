
class IlMchenryArresteeAddresses < ActiveRecord::Base
  self.table_name = 'il_mchenry__arrestee_addresses'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  validates_with IlValidateMd5Hash, on: :create, class_name: self
  after_validation :after_validation_toucher_run_id
  before_create :add_md5
end

class IlMchenryArresteeAliases < ActiveRecord::Base
  self.table_name = 'il_mchenry__arrestee_aliases'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  validates_with IlValidateMd5Hash, on: :create, class_name: self
  before_create :add_md5
end

class IlMchenryArresteeIds < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'il_mchenry__arrestee_ids'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  validates_with IlValidateMd5Hash, on: :create, class_name: self
  before_create :add_md5
end

class IlMchenryArrestees < ActiveRecord::Base
  self.table_name = 'il_mchenry__arrestees'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  validates_with IlValidateMd5Hash, on: :create, class_name: self
  before_create :add_md5

  has_many :addresses, class_name: "IlMchenryArresteeAddresses", foreign_key: :arrestee_id
  has_many :arrests, class_name: "IlMchenryArrests", foreign_key: :arrestee_id
  has_many :arrestee_ids, class_name: "IlMchenryArresteeIds", foreign_key: :arrestee_id
  has_many :arrestee_aliase, class_name: "IlMchenryArresteeAliases", foreign_key: :arrestee_id
end


class IlMchenryArrests < ActiveRecord::Base
  self.table_name = 'il_mchenry__arrests'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  validates_with IlValidateMd5Hash, on: :create, class_name: self
  after_validation :after_validation_toucher_run_id
  before_create :add_md5

  has_many :bonds, class_name: "IlMchenryBonds", foreign_key: :arrest_id
  has_many :charges, class_name: "IlMchenryCharges", foreign_key: :arrest_id
  has_many :holding_facilities, class_name: "IlMchenryHoldingFacilities", foreign_key: :arrest_id

end


class IlMchenryBonds < ActiveRecord::Base
  self.table_name = 'il_mchenry__bonds'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  validates_with IlValidateMd5Hash, on: :create, class_name: self
  before_create :add_md5
end


class IlMchenryCharges < ActiveRecord::Base
  self.table_name = 'il_mchenry__charges'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  validates_with IlValidateMd5Hash, on: :create, class_name: self
  before_create :add_md5
  has_many :charge, class_name: "IlMchenryCharges", foreign_key: :charge_id
  has_many :court_hearing, class_name: "IlMchenryCourtHearing", foreign_key: :charge_id
end


class IlMchenryCourtHearing < ActiveRecord::Base
  self.table_name = 'il_mchenry__court_hearings'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  validates_with IlValidateMd5Hash, on: :create, class_name: self
  before_create :add_md5
end


class IlMchenryHoldingFacilities < ActiveRecord::Base
  self.table_name = 'il_mchenry__holding_facilities'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  validates_with IlValidateMd5Hash, on: :create, class_name: self
  before_create :add_md5
end

class IlMchenryRuns < ActiveRecord::Base
  include Hamster::Granary
  include ModelsHelpers
  self.inheritance_column = :_type_disabled
  self.table_name = 'il_mchenry__runs'
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  self.logger = Logger.new(STDOUT)

  has_many :info, class_name: 'IlMchenryArrestees', foreign_key: :run_id
  has_many :index, class_name: 'IlMchenryIndex', foreign_key: :run_id
end

class IlMchenryMugshots < ActiveRecord::Base
  self.table_name = 'il_mchenry__mugshots'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  validates_with IlValidateMd5Hash, on: :create, class_name: self
  before_create :add_md5
end
