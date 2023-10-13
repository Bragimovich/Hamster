class CookCounty < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: 'il_raw'])
  self.table_name = 'cook_county_death_cause'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
