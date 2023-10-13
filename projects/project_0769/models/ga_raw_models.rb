# frozen_string_literal: true

class GARawContributions < ActiveRecord::Base
  self.table_name = 'GA_RAW_CONTRIBUTIONS'
  establish_connection(Storage[host: :db01, db: :raw_contributions])
end

class GARawCandidates < ActiveRecord::Base
  self.table_name = 'GA_RAW_CANDIDATES'
  establish_connection(Storage[host: :db01, db: :raw_contributions])
end

class GARawCommittees < ActiveRecord::Base
  self.table_name = 'GA_RAW_COMMITTEES'
  establish_connection(Storage[host: :db01, db: :raw_contributions])
end

class Runs < ActiveRecord::Base
  self.table_name = 'GA_RAW_CONTRIBUTIONS__runs'
  establish_connection(Storage[host: :db01, db: :raw_contributions])
end
