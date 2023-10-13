class IdAgencyHeads < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  include Hamster::Granary

  self.table_name = 'id_agency_heads'
  self.logger = Logger.new(STDOUT)
end
