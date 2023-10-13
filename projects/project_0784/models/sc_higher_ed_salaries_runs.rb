# frozen_string_literal: true
class SalariesRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  self.table_name = 'sc_higher_ed_salaries_runs'
  self.inheritance_column = :_type_disabled
end
