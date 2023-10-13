# frozen_string_literal: true

class OhioLawyerStatus < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'ohio'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end


class OhioLawyerStatusRuns < ActiveRecord::Base
  self.table_name = 'ohio_runs'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end