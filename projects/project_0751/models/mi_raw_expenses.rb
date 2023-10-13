# frozen_string_literal: true
class MIRAWExpenses < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'MI_RAW_expenses'
  self.inheritance_column = :_type_disabled
end
