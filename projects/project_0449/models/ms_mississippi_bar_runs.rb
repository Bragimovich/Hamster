class MsMississippiBarRuns < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  include Hamster::Granary

  self.table_name = 'ms_mississippi_bar_runs'
  self.logger = Logger.new(STDOUT)
end
