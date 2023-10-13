# frozen_string_literal: true

class EnergyEM < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  self.inheritance_column = :_type_disabled

  self.table_name = 'energy_em'
end




