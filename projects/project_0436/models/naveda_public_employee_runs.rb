# frozen_string_literal: true

class NavedaPublicRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])

  self.table_name = 'naveda_public_employee_salary_runs'
  self.inheritance_column = :_type_disabled
end
