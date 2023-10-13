class EnergyByState < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db13, db: :usa_raw])
  include Hamster::Granary
  self.table_name = 'energy_incentives_by_state'
end
