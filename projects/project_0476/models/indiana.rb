# frozen_string_literal: true
class Indiana < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'indiana'
  self.inheritance_column = :_type_disabled
end
