# frozen_string_literal: true

class WSCC < ActiveRecord::Base
  self.table_name = 'washington_state_campaign_contributions_csv'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class WSCE < ActiveRecord::Base
  self.table_name = 'washington_state_campaign_expenditures_csv'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class WSCandidates < ActiveRecord::Base
  self.table_name = 'washington_state_candidates_csv'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :usa_raw])
end


class WsccRuns < ActiveRecord::Base
  self.table_name = 'washington_state_campaign_contributions_csv_runs'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end

class WsccGeneral < ActiveRecord::Base
  self.table_name = 'washington_state_campaign_contributions'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :asure_cc])
end
