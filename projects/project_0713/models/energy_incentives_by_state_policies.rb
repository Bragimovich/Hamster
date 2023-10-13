class EnergyByStatePolicies < ActiveRecord::Base
  establish_connection(Storage[host: :db13, db: :usa_raw])
  self.table_name = 'energy_incentives_by_state_policies'
  self.inheritance_column = :_type_disabled
end
