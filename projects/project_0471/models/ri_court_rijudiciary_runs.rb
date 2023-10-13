# frozen_string_literal: true
class RiCourtRijudiciaryRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'ri_court_rijudiciary_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end