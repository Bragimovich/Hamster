# frozen_string_literal: true

class Texas < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
 
  self.table_name = 'texas'
  self.inheritance_column = :_type_disabled
end
