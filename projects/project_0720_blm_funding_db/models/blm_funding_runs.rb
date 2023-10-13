# frozen_string_literal: true
class BlmFundingRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'blm_funding_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
