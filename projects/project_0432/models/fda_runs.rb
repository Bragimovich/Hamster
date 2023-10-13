# frozen_string_literal: true

class FdaRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db13, db: :usa_raw])
  self.table_name = 'fda_runs'
  self.inheritance_column = :_type_disabled
end
