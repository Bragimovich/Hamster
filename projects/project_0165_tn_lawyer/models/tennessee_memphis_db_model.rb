# frozen_string_literal: true

class TennesseeMemphisLawyerStatus < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'tennessee_memphis'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end


class TennesseeMemphisLawyerStatusRuns < ActiveRecord::Base
  self.table_name = 'tennessee_memphis_runs'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end