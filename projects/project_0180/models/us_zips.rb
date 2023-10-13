# frozen_string_literal: true

class USZip < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :hle_resources])
  self.table_name = 'zipcode_data'
end
