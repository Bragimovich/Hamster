# frozen_string_literal: true

class FloridaLawyerStatus < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'florida'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end


class USAStates < ActiveRecord::Base
  self.table_name = 'usa_administrative_division_states'
  establish_connection(Storage[host: :db02, db: :hle_resources])
end




class FloridaLawyerStatusRuns < ActiveRecord::Base
  self.table_name = 'florida_runs'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end