# frozen_string_literal: true

class EquitiesInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'public_companies_stock_ft_com_equities_info'
  self.inheritance_column = :_type_disabled
end
