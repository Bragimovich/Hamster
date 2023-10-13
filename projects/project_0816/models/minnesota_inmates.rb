# frozen_string_literal: true

class MinnesotaInmates < ActiveRecord::Base
  establish_connection(Storage[host: :db01 , db: :crime_inmate])
  self.table_name = 'minnesota_inmates'
  self.inheritance_column = :_type_disabled
end
