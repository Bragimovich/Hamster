DB_SCHEME = :crime_perps__step_1
DB_SERVER = :db01

# class IlWoodfordArresteeAddresses < ActiveRecord::Base
#   self.table_name = 'il_woodford__arrestee_addresses'
#   include Hamster::Granary
#   include ModelsHelpers
#   establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
#   validates_with IlValidateMd5Hash, on: :create, class_name: self
#   after_validation :after_validation_toucher_run_id
#   before_create :add_md5
# end
#
# class IlWoodfordArresteeAliases < ActiveRecord::Base
#   self.table_name = 'il_woodford__arrestee_aliases'
#   include Hamster::Granary
#   include ModelsHelpers
#   establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
#   validates_with IlValidateMd5Hash, on: :create, class_name: self
#   before_create :add_md5
# end
#
# class IlWoodfordArresteeIds < ActiveRecord::Base
#   self.table_name = 'il_woodford__arrestee_ids'
#   include Hamster::Granary
#   include ModelsHelpers
#   establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
#   validates_with IlValidateMd5Hash, on: :create, class_name: self
#   before_create :add_md5
# end

class IlWoodfordArrestees < ActiveRecord::Base
  self.table_name = 'il_woodford__arrestees'
  include Hamster::Granary
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])

  has_many :addresses, class_name: "IlWoodfordArresteeAddresses", foreign_key: :arrestee_id
  has_many :arrests, class_name: "IlWoodfordArrests", foreign_key: :arrestee_id
  has_many :arrestee_ids, class_name: "IlWoodfordArresteeIds", foreign_key: :arrestee_id
  has_many :arrestee_aliase, class_name: "IlWoodfordArresteeAliases", foreign_key: :arrestee_id
end


class IlWoodfordArrests < ActiveRecord::Base
  self.table_name = 'il_woodford__arrests'
  include Hamster::Granary
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])

  has_many :bonds, class_name: "IlWoodfordBonds", foreign_key: :arrest_id
  has_many :charges, class_name: "IlWoodfordCharges", foreign_key: :arrest_id
  has_many :holding_facilities, class_name: "IlWoodfordHoldingFacilities", foreign_key: :arrest_id

end


class IlWoodfordBonds < ActiveRecord::Base
  self.table_name = 'il_woodford__bonds'
  include Hamster::Granary
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])

end


class IlWoodfordCharges < ActiveRecord::Base
  self.table_name = 'il_woodford__charges'
  include Hamster::Granary
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])

  has_many :charge, class_name: "IlWoodfordCharges", foreign_key: :charge_id
  has_many :court_hearing, class_name: "IlWoodfordCourtHearing", foreign_key: :charge_id
end


class IlWoodfordCourtHearing < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'il_woodford__court_hearings'
  include Hamster::Granary
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])

end


class IlWoodfordHoldingFacilities < ActiveRecord::Base
  self.table_name = 'il_woodford__holding_facilities'
  include Hamster::Granary
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])

end

class IlWoodfordRuns < ActiveRecord::Base
  include Hamster::Granary
  self.inheritance_column = :_type_disabled
  self.table_name = 'il_woodford__runs'
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])

  has_many :info, class_name: 'IlWoodfordArrestees', foreign_key: :run_id
  has_many :index, class_name: 'IlWoodfordIndex', foreign_key: :run_id
end

class IlWoodfordMugshots < ActiveRecord::Base
  self.table_name = 'il_woodford__mugshots'
  include Hamster::Granary
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])

end
