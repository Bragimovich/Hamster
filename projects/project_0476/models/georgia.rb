# frozen_string_literal: true
class Georgia < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'georgia'
  self.inheritance_column = :_type_disabled
end
