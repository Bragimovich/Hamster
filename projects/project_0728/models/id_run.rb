class IdRun < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  self.table_name = 'id_run'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
