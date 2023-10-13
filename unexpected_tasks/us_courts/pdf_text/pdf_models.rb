

class UsSAACCasePdfOnAws < ActiveRecord::Base
  self.table_name = 'us_saac_case_pdfs_on_aws'
  establish_connection(Storage[host: :db01, db: :us_courts])
end



class UsSAACCaseReportText < ActiveRecord::Base
  self.table_name = 'us_saac_case_report_text'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end


class UsCasePdfOnAws < ActiveRecord::Base
  self.table_name = 'us_case_pdfs_on_aws'
  establish_connection(Storage[host: :db01, db: :us_courts])
end



class UsCaseReportText < ActiveRecord::Base
  self.table_name = 'us_case_report_text'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end


class UsCasePdfsKeywordToText < ActiveRecord::Base
  self.table_name = 'us_case_pdfs_keyword_to_text'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

class UsCasePdfsUniqueCategories  < ActiveRecord::Base
  self.table_name = 'us_case_pdfs_unique_categories'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

class UsCaseKeywordToDescription < ActiveRecord::Base
  self.table_name = 'us_case_keyword_to_description'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end


class UsCaseKeywordUniqueCategories  < ActiveRecord::Base
  self.table_name = 'us_case_keyword_unique_category'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end
