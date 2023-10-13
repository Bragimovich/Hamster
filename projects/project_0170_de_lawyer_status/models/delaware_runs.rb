# frozen_string_literal: true

class DelawareRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'delaware_runs'
  self.inheritance_column = :_type_disabled
end
