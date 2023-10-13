# frozen_string_literal: true

class IllinoisByLocation < ActiveRecord::Base
  self.table_name = 'illinois_by_location'
  establish_connection(Storage[host: :db01, db: :us_sales_taxes])
end
