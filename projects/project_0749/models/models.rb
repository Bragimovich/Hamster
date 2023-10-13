# frozen_string_literal: true

class NvRawRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'NV_RAW_RUNS'
  self.inheritance_column = :_type_disabled
end

class NvRawExpense < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'NV_RAW_Expenses'
  self.inheritance_column = :_type_disabled
end

class NvRawContribution < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'NV_RAW_Contributions'
  self.inheritance_column = :_type_disabled
end

class NvRawContributor < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'NV_RAW_Contributors'
  self.inheritance_column = :_type_disabled
end

class NvRawReport < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'NV_RAW_Reports'
  self.inheritance_column = :_type_disabled
end

class NvRawCandidate < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'NV_RAW_Candidates'
  self.inheritance_column = :_type_disabled
end

class NvRawGroup < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'NV_RAW_Groups'
  self.inheritance_column = :_type_disabled
end
