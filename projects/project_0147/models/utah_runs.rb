# frozen_string_literal: true

class UtahRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'utah_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
