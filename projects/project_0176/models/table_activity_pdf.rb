# frozen_string_literal: true

class TableActivityPDF < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  
  self.table_name = 'ca_saac_case_relations_activity_pdf'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
