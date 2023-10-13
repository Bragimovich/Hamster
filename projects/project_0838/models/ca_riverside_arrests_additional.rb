# frozen_string_literal: true

class CaRiversideArrestsAdditional < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :crime_inmate])
    self.table_name = 'ca_riverside_arrests_additional'
    self.inheritance_column = :_type_disabled
end
