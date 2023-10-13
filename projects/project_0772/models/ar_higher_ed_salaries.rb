# frozen_string_literal: true
class ArHigherEdSalaries < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  self.table_name = 'ar_higher_ed_salaries'
  self.inheritance_column = :_type_disabled
end
