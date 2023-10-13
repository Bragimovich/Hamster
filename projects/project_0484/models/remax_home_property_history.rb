# frozen_string_literal: true

class RemaxHomePropertyHistory < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :re_sales])
  self.table_name = 'remax_home_listings_property_history'
  self.inheritance_column = :_type_disabled
end
