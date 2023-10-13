class MaPublic < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: 'usa_raw'])
  self.table_name = 'ma_public_employee_salaries'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
