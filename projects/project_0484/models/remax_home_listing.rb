# frozen_string_literal: true

class RemaxHomeListing < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :re_sales])
  self.table_name = 'remax_home_listings'
  self.inheritance_column = :_type_disabled
end
