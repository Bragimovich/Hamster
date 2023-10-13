# frozen_string_literal: true

class UsCourtsSAAC < ActiveRecord::Base
  self.table_name = 'us_courts_saac'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end



class UsSaacCaseInfoRuns < ActiveRecord::Base
  self.table_name = 'us_saac_case_info_runs'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class UsSaacCasePartyRuns < ActiveRecord::Base
  self.table_name = 'us_saac_case_party_runs'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class UsSaacCaseActivitiesRuns < ActiveRecord::Base
  self.table_name = 'us_saac_case_activities_runs'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class UsSaacCasePdfsOnAwsRuns < ActiveRecord::Base
  self.table_name = 'us_saac_case_pdfs_on_aws_runs'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class UsSaacCaseAdditionalInfoRuns < ActiveRecord::Base
  self.table_name = 'us_saac_case_additional_info_runs'
  establish_connection(Storage[host: :db01, db: :us_courts])
end




class UsSaacCaseConsolidationsRuns < ActiveRecord::Base
  self.table_name = 'us_saac_case_consolidations_runs'
  establish_connection(Storage[host: :db01, db: :us_courts])
end


class TransferCasesTableAnalysis < ActiveRecord::Base
  self.table_name = 'transfer_cases_table'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

