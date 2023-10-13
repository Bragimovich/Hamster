class IdahoRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'idaho_voter_registrations_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
