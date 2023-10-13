# frozen_string_literal: true

class EquitiesPrices < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'public_companies_stock_ft_com_equities_prices'
  self.inheritance_column = :_type_disabled
end
