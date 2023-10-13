# frozen_string_literal: true

class NavedaPublic < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])

  self.table_name = 'nv_public_employee_salary'
  self.inheritance_column = :_type_disabled
end
