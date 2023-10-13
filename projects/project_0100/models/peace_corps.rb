class PeaceCorps < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary
  
  self.table_name = 'peace_corps'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
