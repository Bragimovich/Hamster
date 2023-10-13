class MIHigherEducationSalaries < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'mi_higher_education_salaries'
  self.inheritance_column = :_type_disabled
end
