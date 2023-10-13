class TxSaacCaseInfo < ActiveRecord::Base
  self.table_name = "tx_saac_case_info"
  self.inheritance_column = nil
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
end

class TxSaacCaseParty < ActiveRecord::Base
  self.table_name = "tx_saac_case_party"
  self.inheritance_column = nil
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
end

class TxSaacCaseActivities < ActiveRecord::Base
  self.table_name = "tx_saac_case_activities"
  self.inheritance_column = nil
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
end

class TxSaacCasePdfsOnAws < ActiveRecord::Base
  self.table_name = "tx_saac_case_pdfs_on_aws"
  self.inheritance_column = nil
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
  # your code if necessary
end

class TxSaacCaseRelationsActivityPdf < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
  # your code if necessary
end

class TxSaacCaseAdditionalInfo < ActiveRecord::Base
  self.table_name = "tx_saac_case_additional_info"
  self.inheritance_column = nil
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
end