class CaseRelationsInfoPdf < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary

  self.table_name = 'ca_saac_case_relations_info_pdf'
  self.logger = Logger.new(STDOUT)
end