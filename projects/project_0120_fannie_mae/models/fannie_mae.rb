# frozen_string_literal: true

# require_relative '../config/database_config'

class FannieMae < ActiveRecord::Base
  establish_connection(Storage.use(host: :db02, db: :press_releases))
  self.table_name = "fannie_mae"
  self.inheritance_column = nil
  # your code if necessary
end
