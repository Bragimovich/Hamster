# frozen_string_literal: true

class OrOsbar < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'or_osbar'
  include Hamster::Granary
  establish_connection(Storage[host: :db01, db: :lawyer_status]) 
end
