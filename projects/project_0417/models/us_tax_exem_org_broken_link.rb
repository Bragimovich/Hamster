class USTaxExemOrgBrokenLink < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :woke_project])
  include Hamster::Granary

  self.table_name = 'non_profit_xml__broken_links'
  self.logger = Logger.new(STDOUT)
end
