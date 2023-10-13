class CoGradSocial < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'co_graduation_social'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
