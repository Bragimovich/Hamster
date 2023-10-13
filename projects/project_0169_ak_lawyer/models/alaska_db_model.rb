# frozen_string_literal: true

class AlaskaLawyerStatus < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = 'alaska'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end


class AlaskaLawyerStatusRuns < ActiveRecord::Base
  self.table_name = 'alaska_runs'
  establish_connection(Storage[host: :db01, db: :lawyer_status])
end