# frozen_string_literal: true

class DelawareVoterRegistrationsRun < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'delaware_voter_registrations_run'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
