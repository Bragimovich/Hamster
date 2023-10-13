
class IlLakeCountySheriffRuns < ActiveRecord::Base
  include Hamster::Granary
  self.inheritance_column = :_type_disabled
  self.table_name = 'il_lake_county_sheriff_runs'
  establish_connection(Storage[host: :db11, db: :usa_raw])
  self.logger = Logger.new(STDOUT)

  has_many :info, class_name: 'IlLakeCountySheriffInfo', foreign_key: :run_id
  has_many :index, class_name: 'IlLakeCountySheriffIndex', foreign_key: :run_id
end
