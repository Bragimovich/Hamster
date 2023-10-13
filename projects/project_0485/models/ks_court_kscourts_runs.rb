# frozen_string_literal: true

class KSCourtKscourtsRuns < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  include Hamster::Granary
  
  self.table_name = 'ks_court_kscourts_runs'
  self.logger = Logger.new(STDOUT)
end