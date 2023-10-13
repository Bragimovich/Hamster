# frozen_string_literal: true
class ArizonaVoterRegistrationRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'arizona_voter_registrations_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new($stdout)
end
