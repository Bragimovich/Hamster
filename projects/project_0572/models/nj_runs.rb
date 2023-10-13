# frozen_string_literal: true
class NjRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'nj_state_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
