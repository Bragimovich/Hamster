class NaturalResources < ActiveRecord::Base
  include Hamster::Granary
  include Hamster::Loggable
  self.inheritance_column = :_type_disabled

  establish_connection(Storage[host: :db02, db: :press_releases])
  self.table_name = 'us_dept_natural_resources'
end
