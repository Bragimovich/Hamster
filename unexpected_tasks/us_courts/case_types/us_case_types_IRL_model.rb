
class UsCaseTypesIRLCategorized < ActiveRecord::Base
  self.table_name = 'analysis_litigation_IRL_types__courthouses'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end


class CaseReportAwsText < ActiveRecord::Base
  self.table_name = 'us_case_report_aws_text'
  establish_connection(Storage[host: :db01, db: :us_courts])
end


class UsCaseReportIRL < ActiveRecord::Base
  self.table_name = 'analysis_litigation_IRL_types__pdfs'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end


class LitigationCaseTypeIRLUniqueCategories < ActiveRecord::Base
  self.table_name = 'litigation_case_type__IRL_unique_categories'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end


class LitigationCaseTypeIRLKeywordToText < ActiveRecord::Base
  self.table_name = 'litigation_case_type__IRL_keyword_to_text'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

class LitigationCaseTypeIRLPdfsUniqueCategories < ActiveRecord::Base
  self.table_name = 'litigation_case_type__IRL_pdfs_unique_categories'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

class LitigationCaseTypeIRLKeywords < ActiveRecord::Base
  self.table_name = 'litigation_case_type__IRL_keywords'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

class LitigationCaseTypeMatchingKeywords < ActiveRecord::Base
  self.table_name = 'litigation_case_type__matching_keyword'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

class AnalysisLitigationCourtsActivitiesKeywords < ActiveRecord::Base
  self.table_name = 'analysis_litigation_courts_activities__keywords'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

class LitigationCaseActivityDescMatchingKeywords < ActiveRecord::Base
  self.table_name = 'litigation_case_activity_desc__matching_keyword'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end


class LitigationKeywordToCase < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'litigation_keyword_to_case'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

class LitigationCaseToUniqueCategory < ActiveRecord::Base
  self.table_name = 'litigation_case_to_unique_category'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end


