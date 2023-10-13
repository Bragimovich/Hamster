# frozen_string_literal: true
class Michigan < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'michigan'
  self.inheritance_column = :_type_disabled
end
