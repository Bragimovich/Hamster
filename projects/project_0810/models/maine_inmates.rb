# frozen_string_literal: true
class MaineInmates < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :crime_inmate])
    self.table_name = 'maine_inmates'
    self.inheritance_column = :_type_disabled
end
