class ChicagoFederationMusiciansRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :il_raw])

  self.table_name = 'chicago_federation_musicians_runs'
  self.inheritance_column = :_type_disabled
end
