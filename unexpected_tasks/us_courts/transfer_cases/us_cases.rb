# frozen_string_literal: true

class UsCaseLawyer < ActiveRecord::Base
  self.table_name = 'us_case_lawyer'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class UsCaseParty < ActiveRecord::Base
  self.table_name = 'us_case_party'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class UsCaseInfo < ActiveRecord::Base
  self.table_name = 'us_case_info'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class UsCaseActivities < ActiveRecord::Base
  self.table_name = 'us_case_activities'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class TransferCasesTableAnalysis < ActiveRecord::Base
  self.table_name = 'transfer_cases_table'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end








class UsCasePartyCourts < ActiveRecord::Base
  self.table_name = 'us_case_party'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class UsCaseInfoCourts < ActiveRecord::Base
  self.table_name = 'us_case_info'
  establish_connection(Storage[host: :db01, db: :us_courts])
end


class UsCaseActivitiesCourts < ActiveRecord::Base
  self.table_name = 'us_case_activities'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class UsCaseActivitiesPDFCourts < ActiveRecord::Base
  self.table_name = 'us_case_activities_pdf'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class UsCaseJudgmentCourts < ActiveRecord::Base
  self.table_name = 'us_case_judgment'
  establish_connection(Storage[host: :db01, db: :us_courts])
end


class UsCasePdfsOnAwsCourts < ActiveRecord::Base
  self.table_name = 'us_case_pdfs_on_aws'
  establish_connection(Storage[host: :db01, db: :us_courts])
end


class UsCaseInfoCourtsRuns < ActiveRecord::Base
  self.table_name = 'us_case_info_runs'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class UsCasePartyCourtsRuns < ActiveRecord::Base
  self.table_name = 'us_case_party_runs'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class UsCaseActivitiesCourtsRuns < ActiveRecord::Base
  self.table_name = 'us_case_activities_runs'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class UsCaseJudgmentCourtsRuns < ActiveRecord::Base
  self.table_name = 'us_case_judgment_runs'
  establish_connection(Storage[host: :db01, db: :us_courts])
end


class UsCasePdfsOnAwsCourtsRuns < ActiveRecord::Base
  self.table_name = 'us_case_pdfs_on_aws_runs'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class CaseTypesDivided < ActiveRecord::Base
  self.table_name = 'litigation_case_type__john'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end


class CaseTypeCategoryId < ActiveRecord::Base
  self.table_name = 'litigation_case_type_categories_id__john'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

class CaseTypeCategory < ActiveRecord::Base
  self.table_name = 'litigation_case_type_categories__john'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end


def db_root_model(type)
  model =
    case type
    when :info
      UsCaseInfoCourts
    when :party
      UsCasePartyCourts
    when :activities
      UsCaseActivitiesCourts
    when :judgment
      UsCaseJudgmentCourts
    when :pdfs_on_aws
      UsCasePdfsOnAwsCourts
    end
  model
end