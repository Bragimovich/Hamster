class WvScCasePdfsOnAws < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  include Hamster::Granary

  self.table_name = 'wv_sc_case_pdfs_on_aws'
  self.logger = Logger.new(STDOUT)
end
