# frozen_string_literal: true

class NevadaLawyerStatus < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'nevada'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end


class NevadaLawyerStatusRuns < ActiveRecord::Base
  self.table_name = 'nevada_runs'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end