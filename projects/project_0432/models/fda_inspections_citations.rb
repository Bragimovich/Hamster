class FdaInspectionsCitations < ActiveRecord::Base
  establish_connection(Storage[host: :db13, db: :usa_raw])
  self.table_name = 'fda_inspections_citations_temp'
  self.inheritance_column = :_type_disabled
end
