# frozen_string_literal: true

class class BuildingPermits < ActiveRecord::Base
  include Hamster::Loggable
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary
  
  self.table_name = 'building_permits_by_county'
end
