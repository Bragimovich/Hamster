# frozen_string_literal: true

class DbStates < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :hle_resources])
  self.table_name = 'zip_factoids'
  self.inheritance_column = :_type_disabled
end
