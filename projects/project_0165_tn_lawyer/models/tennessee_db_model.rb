# frozen_string_literal: true

class TennesseeLawyerStatus < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'tennessee'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end


class TennesseeLawyerStatusRuns < ActiveRecord::Base
  self.table_name = 'tennessee_runs'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end