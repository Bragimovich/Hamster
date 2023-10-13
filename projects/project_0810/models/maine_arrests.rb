# frozen_string_literal: true
class MaineArrests < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :crime_inmate])
    self.table_name = 'maine_arrests'
    self.inheritance_column = :_type_disabled
end
