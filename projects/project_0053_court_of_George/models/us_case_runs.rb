# frozen_string_literal: true

class UsCaseInfoRuns < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :us_courts))
  self.table_name = 'us_case_info_runs'
  include Hamster::Granary
end

class UsCasePartyRuns < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :us_courts))
  self.table_name = 'us_case_party_runs'
  include Hamster::Granary
end

class UsCaseActivitiesRuns < ActiveRecord::Base
  establish_connection(Storage.use(host: :db01, db: :us_courts))
  self.table_name = 'us_case_activities_runs'
  include Hamster::Granary
end