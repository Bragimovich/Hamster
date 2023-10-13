class MAACAws < ActiveRecord::Base
  self.table_name = 'maac_case_pdfs_on_aws'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

