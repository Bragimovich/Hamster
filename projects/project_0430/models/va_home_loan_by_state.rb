# frozen_string_literal: true

class VaState < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'va_home_loan_by_state'
  self.inheritance_column = :_type_disabled
end
