
class UsCaseTypesRachelleCategorized < ActiveRecord::Base
  self.table_name = 'analysis_litigation_rachelle_types__courthouses'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end


class CaseReportAwsText < ActiveRecord::Base
  self.table_name = 'us_case_report_aws_text'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class UsCaseReportText < ActiveRecord::Base
  self.table_name = 'us_case_report_text'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end


class UsCaseReportRachelle < ActiveRecord::Base
  self.table_name = 'analysis_litigation_rachelle_types__pdfs'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end
