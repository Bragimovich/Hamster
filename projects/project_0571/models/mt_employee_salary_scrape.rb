# frozen_string_literal: true

class MTEmployeeSalary < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'MT_employee_salary_scrape'
  self.inheritance_column = :_type_disabled
end
