# frozen_string_literal: true

class CaRiversideArrests < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :crime_inmate])
    self.table_name = 'ca_riverside_arrests'
    self.inheritance_column = :_type_disabled
end
