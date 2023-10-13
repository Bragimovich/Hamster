# frozen_string_literal: true
class EeocRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'eeoc_runs'
  self.inheritance_column = :_type_disabled
end
