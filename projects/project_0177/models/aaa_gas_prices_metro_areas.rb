class AaaGasPricesMetro < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  include Hamster::Loggable
  include Hamster::Granary

  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'aaa_gas_prices_metro_areas_daily'
end
