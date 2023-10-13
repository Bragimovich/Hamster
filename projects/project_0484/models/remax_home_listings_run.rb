# frozen_string_literal: true

class RemaxHomeListingsRun < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :re_sales])
  self.table_name = 'remax_home_listings_runs'
  self.inheritance_column = :_type_disabled
end
