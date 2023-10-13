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

class UsCaseActivitiesPDF < ActiveRecord::Base
  self.table_name = 'us_case_activities_pdf'
  establish_connection(Storage[host: :db01, db: :us_court_cases])
end




class UsCasePartyCourts < ActiveRecord::Base
  self.table_name = 'us_case_party'
  establish_connection(Storage[host: :db01, db: :us_courts])
end

class UsCaseInfoCourts < ActiveRecord::Base
  self.table_name = 'us_case_info'
  establish_connection(Storage[host: :db01, db: :us_courts])
end


# class UsCaseActivitiesCourts < ActiveRecord::Base
#   self.table_name = 'us_case_activities'
#   establish_connection(Storage[host: :db01, db: :us_courts])
# end