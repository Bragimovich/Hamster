# frozen_string_literal: true

class PennsylvaniaRun < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
 
  self.table_name = 'pennsylvania_voter_registrations_run'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
