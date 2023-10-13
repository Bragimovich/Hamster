# frozen_string_literal: true
class CaliforniaVoterRegistration < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'california_voter_registrations'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new($stdout)
end
