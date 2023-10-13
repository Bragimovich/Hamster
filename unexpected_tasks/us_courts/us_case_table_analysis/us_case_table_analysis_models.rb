
class UsCaseDistinctDataPoints < ActiveRecord::Base
  self.table_name = 'us_case_distinct_data_points'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

class UsCaseCourthouseDataPointAnalysis < ActiveRecord::Base
  self.table_name = 'us_case_courthouse_data_point_analysis'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

class UsCaseLitigationDataSetTables < ActiveRecord::Base
  self.table_name = 'us_case_litigation_data_set_tables'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

class UsCaseCourthouseCounts < ActiveRecord::Base
  self.table_name = 'us_case_courthouse_counts'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

class UsCaseCourthouseLogs < ActiveRecord::Base
  self.table_name = 'us_case_courthouse_logs'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end


class UsCaseOverallDataAnalysis < ActiveRecord::Base
  self.table_name = 'us_case_overall_data_analysis'
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

class UsCaseCourthouseAverageCounts < ActiveRecord::Base
  self.table_name = "us_case_courthouse_average_counts"
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end

class ActivityDescUnique < ActiveRecord::Base
  self.table_name = "activity_desc_unique"
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end



class UsCaseInfo < ActiveRecord::Base
  self.table_name = 'us_case_info'
  establish_connection(Storage[host: :db01, db: :us_courts])
end


class UsSAACCaseInfo < ActiveRecord::Base
  self.table_name = 'us_saac_case_info'
  establish_connection(Storage[host: :db01, db: :us_courts])
end
