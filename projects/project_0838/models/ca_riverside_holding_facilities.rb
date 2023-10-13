# frozen_string_literal: true

class CaRiversideHoldingsFacilities < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :crime_inmate])
    self.table_name = 'ca_riverside_holding_facilities'
    self.inheritance_column = :_type_disabled
end
