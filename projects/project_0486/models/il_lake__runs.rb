
class IlLakeRuns < ActiveRecord::Base
  include Hamster::Granary
  include ModelsHelpers
  self.inheritance_column = :_type_disabled
  self.table_name = 'il_lake__runs'
  establish_connection(Storage[host: DB_SERVER, db: DB_SCHEME])
  self.logger = Logger.new(STDOUT)

  has_many :info, class_name: 'IlLakeArrestees', foreign_key: :run_id
  has_many :index, class_name: 'IlLakeIndex', foreign_key: :run_id
end


