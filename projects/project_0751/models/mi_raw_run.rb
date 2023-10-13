# frozen_string_literal: true
class MIRAWRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :raw_contributions])
  self.table_name = 'MI_RAW_runs'
  self.inheritance_column = :_type_disabled
end
