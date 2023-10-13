
class IlKaneArresteeAddresses < ActiveRecord::Base
  self.table_name = 'il_kane__arrestee_addresses'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
end

class IlKaneArresteeAliases < ActiveRecord::Base
  self.table_name = 'il_kane__arrestee_aliases'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
end

class IlKaneArresteeIds < ActiveRecord::Base
  self.table_name = 'il_kane__arrestee_ids'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
end

class IlKaneArrestees < ActiveRecord::Base
  self.table_name = 'il_kane__arrestees'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  has_many :addresses, class_name: "IlKaneArresteeAddresses", foreign_key: :arrestee_id
  has_many :arrests, class_name: "IlKaneArrests", foreign_key: :arrestee_id
  has_many :arrestee_ids, class_name: "IlKaneArresteeIds", foreign_key: :arrestee_id
  has_many :arrestee_aliase, class_name: "IlKaneArresteeAliases", foreign_key: :arrestee_id
end


class IlKaneArrests < ActiveRecord::Base
  self.table_name = 'il_kane__arrests'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])

  has_many :bonds, class_name: "IlKaneBonds", foreign_key: :arrest_id
  has_many :charges, class_name: "IlKaneCharges", foreign_key: :arrest_id
  has_many :holding_facilities, class_name: "IlKaneHoldingFacilities", foreign_key: :arrest_id

end


class IlKaneBonds < ActiveRecord::Base
  self.table_name = 'il_kane__bonds'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
end


class IlKaneCharges < ActiveRecord::Base
  self.table_name = 'il_kane__charges'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  has_many :charge, class_name: "IlKaneCharges", foreign_key: :charge_id
  has_many :court_hearing, class_name: "IlKaneCourtHearing", foreign_key: :charge_id
end


class IlKaneCourtHearing < ActiveRecord::Base
  self.table_name = 'il_kane__court_hearings'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
end


class IlKaneHoldingFacilities < ActiveRecord::Base
  self.table_name = 'il_kane__holding_facilities'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
end

class IlKaneRuns < ActiveRecord::Base
  include Hamster::Granary
  include ModelsHelpers
  self.table_name = 'il_kane__runs'
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  has_many :info, class_name: 'IlKaneArrestees', foreign_key: :run_id
  has_many :index, class_name: 'IlKaneIndex', foreign_key: :run_id
end

class IlKaneMugshots < ActiveRecord::Base
  self.table_name = 'il_kane__mugshots'
  include Hamster::Granary
  include ModelsHelpers
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
end


