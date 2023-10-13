# frozen_string_literal: true

class DECaseInfo < ActiveRecord::Base
  self.table_name = 'de_case_info'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end


class DECaseParty < ActiveRecord::Base
  self.table_name = 'de_case_party'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class DECaseActivities < ActiveRecord::Base
  self.table_name = 'de_case_activities'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class DECasePdfsOnAws < ActiveRecord::Base
  self.table_name = 'de_case_pdfs_on_aws'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end


class DECaseRelationsActivityPdf < ActiveRecord::Base
  self.table_name = 'de_case_relations_activity_pdf'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class DECaseRuns < ActiveRecord::Base
  self.table_name = 'de_case_runs'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end
