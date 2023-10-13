# frozen_string_literal: true

class MinnesotaMugshots < ActiveRecord::Base
  establish_connection(Storage[host: :db01 , db: :crime_inmate])
  self.table_name = 'minnesota_mugshots'
  self.inheritance_column = :_type_disabled
end
