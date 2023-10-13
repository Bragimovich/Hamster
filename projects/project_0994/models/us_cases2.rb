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



class CaseTypesDivided < ActiveRecord::Base
  self.table_name = 'us_case_types'
  establish_connection(Storage[host: :db01, db: :us_courts])
end


class CaseTypeCategoryId < ActiveRecord::Base
  self.table_name = 'us_case_type_categories_id'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class CaseTypeCategory < ActiveRecord::Base
  self.table_name = 'us_case_type_categories'
  establish_connection(Storage[host: :db01, db: :us_courts])
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
    end
  model
end



class CaseReport < ActiveRecord::Base
  self.table_name = 'us_case_report'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class CaseReportPacer < ActiveRecord::Base
  self.table_name = 'us_case_report_pacer'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class CaseReportAws < ActiveRecord::Base
  self.table_name = 'us_case_report_aws'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class CaseReportAwsText < ActiveRecord::Base
  self.table_name = 'us_case_report_aws_text'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class NYCaseInfo < ActiveRecord::Base
  self.table_name = 'NY_case_info'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end

class NYCaseActivities < ActiveRecord::Base
  self.table_name = 'NY_case_activities'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end