class UsdaFsa < ActiveRecord::Base
  include Hamster::Loggable
  include Hamster::Granary
  self.inheritance_column = :_type_disabled

  establish_connection(Storage[host: :db02, db: :press_releases])
  self.table_name = 'usda_fsa'
end

