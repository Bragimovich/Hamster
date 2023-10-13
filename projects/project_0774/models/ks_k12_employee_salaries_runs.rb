# frozen_string_literal: true
class KsRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  self.table_name = 'ks_k12_employee_salaries_runs'
  self.inheritance_column = :_type_disabled
end
