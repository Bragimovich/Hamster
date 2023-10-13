class USTaxExemOrgExecutives < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :woke_project])
  include Hamster::Granary

  self.table_name = 'non_profit_xml__executives'
  self.logger = Logger.new(STDOUT)
end
