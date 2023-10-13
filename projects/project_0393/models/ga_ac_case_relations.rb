# frozen_string_literal: true
class GaAcCaseRelationsInfoPdf < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'ga_ac_case_relations_info_pdf'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
