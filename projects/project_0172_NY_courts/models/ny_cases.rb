# frozen_string_literal: true

class NYCaseInfo < ActiveRecord::Base
  self.table_name = 'NY_case_info'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NYCaseJudgement < ActiveRecord::Base
  self.table_name = 'NY_case_judgment'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NYCaseActivities < ActiveRecord::Base
  self.table_name = 'NY_case_activities'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NYCaseParty < ActiveRecord::Base
  self.table_name = 'NY_case_party'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NYCaseLawyer < ActiveRecord::Base
  self.table_name = 'NY_case_lawyer'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NYCasePdfsOnAws < ActiveRecord::Base
  self.table_name = 'NY_case_pdfs_on_aws'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NYCaseRelationsActivity < ActiveRecord::Base
  self.table_name = 'NY_case_relations_activity_pdf'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end


class USCaseInfo < ActiveRecord::Base
  self.table_name = 'us_case_info'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end



class NYCaseRuns < ActiveRecord::Base
  self.table_name = 'NY_case_runs'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end


class NYCaseIndex < ActiveRecord::Base
  self.table_name = 'NY_case_index'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end