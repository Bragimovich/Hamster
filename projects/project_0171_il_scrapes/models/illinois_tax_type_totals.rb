# frozen_string_literal: true

class IllinoisTaxTypeTotals < ActiveRecord::Base
  self.table_name = 'illinois_tax_type_totals'
  establish_connection(Storage[host: :db01, db: :us_sales_taxes])
end
