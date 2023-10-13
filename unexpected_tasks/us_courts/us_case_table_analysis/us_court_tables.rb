
class UsCaseInfo < ActiveRecord::Base
  self.table_name = 'us_case_info'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class UsSAACCaseInfo < ActiveRecord::Base
  self.table_name = 'us_saac_case_info'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class UsCaseActivities < ActiveRecord::Base
  self.table_name = 'us_case_activities'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class UsSAACCaseActivities < ActiveRecord::Base
  self.table_name = 'us_saac_case_activities'
  establish_connection(Storage[host: :db01, db: :us_courts])
end


