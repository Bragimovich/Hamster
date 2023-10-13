# frozen_string_literal: true

class VaReports < ActiveRecord::Base
  establish_connection(Storage[host: :db02, db: :inspector_general])
    
  self.table_name = 'va_office_reports'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
