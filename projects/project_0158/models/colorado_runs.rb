class ColoradoRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  self.table_name = 'colorado_runs'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new(STDOUT)
end
