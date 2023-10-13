# frozen_string_literal: true

class NCCaseInfo < ActiveRecord::Base
  self.table_name = 'nc_saac_case_info'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NCCaseAdditionalInfo < ActiveRecord::Base
  self.table_name = 'nc_saac_case_additional_info'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NCCaseParty < ActiveRecord::Base
  self.table_name = 'nc_saac_case_party'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NCCaseActivities < ActiveRecord::Base
  self.table_name = 'nc_saac_case_activities'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NCCasePdfsOnAws < ActiveRecord::Base
  self.table_name = 'nc_saac_case_pdfs_on_aws'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NCCaseRelationsActivityPdf < ActiveRecord::Base
  self.table_name = 'nc_saac_case_relations_activity_pdf'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NCCaseRelationsInfoPdf < ActiveRecord::Base
  self.table_name = 'nc_saac_case_relations_info_pdf'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NCCaseRuns < ActiveRecord::Base
  self.table_name = 'nc_saac_case_runs'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end
