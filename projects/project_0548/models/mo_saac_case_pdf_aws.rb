class MoSaacCasePdfAws < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'mo_saac_case_pdfs_on_aws'
  self.inheritance_column =:_type_disabled
  self.logger = Logger.new(STDOUT)
end