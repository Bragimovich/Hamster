# frozen_string_literal: true

class MinnesotaArrests < ActiveRecord::Base
  establish_connection(Storage[host: :db01 , db: :crime_inmate])
  self.table_name = 'minnesota_arrests'
  self.inheritance_column = :_type_disabled
end
