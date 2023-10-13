# frozen_string_literal: true

class VaLocations < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :inspector_general])
      
  self.table_name = 'va_office_reports_locations'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)  
end
