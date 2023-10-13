class Nyshcr_runs < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :press_releases])
  include Hamster::Granary

  self.table_name = 'nyshcr_runs'
  self.logger = Logger.new(STDOUT)
end