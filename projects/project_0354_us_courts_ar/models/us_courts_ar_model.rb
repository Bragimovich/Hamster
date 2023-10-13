# frozen_string_literal: true

class ARCaseInfo < ActiveRecord::Base
  self.table_name = 'ar_saac_case_info'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end


class ARCaseParty < ActiveRecord::Base
  self.table_name = 'ar_saac_case_party'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class ARCaseActivities < ActiveRecord::Base
  self.table_name = 'ar_saac_case_activities'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class ARCasePdfsOnAws < ActiveRecord::Base
  self.table_name = 'ar_saac_case_pdfs_on_aws'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end


class ARCaseRelationsActivityPdf < ActiveRecord::Base
  self.table_name = 'ar_saac_case_relations_activity_pdf'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class ARCaseRuns < ActiveRecord::Base
  self.table_name = 'ar_saac_case_runs'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class ReconnectManagerDB02 < ActiveRecord::Base
  establish_connection(Storage.use(host: :db02, db: :mysql))
end
