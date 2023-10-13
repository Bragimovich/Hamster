# frozen_string_literal: true

class NorthDakota < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])

  self.table_name = 'north_dakota'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
