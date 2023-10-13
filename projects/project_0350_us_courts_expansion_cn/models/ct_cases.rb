class CtSaacCaseActivities < ActiveRecord::Base
  self.table_name = "ct_saac_case_activities"
  self.inheritance_column = nil
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
end

class CtSaacCaseAdditionalInfo < ActiveRecord::Base
  self.table_name = "ct_saac_case_additional_info"
  self.inheritance_column = nil
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
end

class CtSaacCaseInfo < ActiveRecord::Base
  self.table_name = "ct_saac_case_info"
  self.inheritance_column = nil
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
end

class CtSaacCaseParty < ActiveRecord::Base
  self.table_name = "ct_saac_case_party"
  self.inheritance_column = nil
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
end

class CtSaacCasePdfsOnAws < ActiveRecord::Base
  self.table_name = "ct_saac_case_pdfs_on_aws"
  self.inheritance_column = nil
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
  # your code if necessary
end

class CtSaacCaseRelationsActivityPdf < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :us_court_cases))
  # your code if necessary
end