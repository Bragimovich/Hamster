class FarmSubsidy < ActiveRecord::Base
    include Hamster::Loggable

    establish_connection(Storage[host: :db01, db: :usa_raw])
    self.table_name = 'us_fsa_subsidies'
    self.inheritance_column = :_type_disabled
end

class FarmSubsidiesRun < ActiveRecord::Base
    include Hamster::Loggable

    establish_connection(Storage[host: :db01, db: :usa_raw])
    self.table_name = 'farm_subsidies_runs'
    self.inheritance_column = :_type_disabled
end