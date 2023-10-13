# frozen_string_literal: true

class LaScCaseRelationsActivityPdf < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary

  self.table_name = 'la_sc_case_relations_activity_pdf'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
