class UsDosBeba < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  include Hamster::Loggable
  include Hamster::Granary

  establish_connection(Storage[host: :db02, db: :press_releases])
  self.table_name = 'us_dos_beba'
end
