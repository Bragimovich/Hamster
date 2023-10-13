# frozen_string_literal: true
class MaineCharges < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :crime_inmate])
    self.table_name = 'maine_charges'
    self.inheritance_column = :_type_disabled
end
