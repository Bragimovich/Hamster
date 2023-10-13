class Runs < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'counts_of_death_by_cause_week_state_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end