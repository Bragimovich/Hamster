# frozen_string_literal: true

class FSCALPdfs < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  
  self.table_name = 'florida_supreme_court_acknowledgment_letter_pdfs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
