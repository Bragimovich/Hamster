# frozen_string_literal: true

class NECaseInfo < ActiveRecord::Base
  self.table_name = 'ne_saac_case_info'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NECaseAdditionalInfo < ActiveRecord::Base
  self.table_name = 'ne_saac_case_additional_info'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NECaseParty < ActiveRecord::Base
  self.table_name = 'ne_saac_case_party'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NECaseActivities < ActiveRecord::Base
  self.table_name = 'ne_saac_case_activities'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NECasePdfsOnAws < ActiveRecord::Base
  self.table_name = 'ne_saac_case_pdfs_on_aws'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NECaseRelationsActivityPdf < ActiveRecord::Base
  self.table_name = 'ne_saac_case_relations_activity_pdf'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end


class NECaseRuns < ActiveRecord::Base
  self.table_name = 'ne_saac_case_runs'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end
