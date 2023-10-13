# frozen_string_literal: true
class InRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'in_runs'
  self.inheritance_column = :_type_disabled
end
