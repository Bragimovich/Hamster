# frozen_string_literal: true

class WyomingLawyerStatus < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'wyoming'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end


class WyomingLawyerStatusRuns < ActiveRecord::Base
  self.table_name = 'wyoming_runs'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end