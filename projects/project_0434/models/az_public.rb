class AzPublic < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'az_public_employee_salary_temp'
  self.inheritance_column = :_type_disabled
end
