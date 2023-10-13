class MaxprepsComRuns < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :limpar_maxpreps_com])

  self.table_name = 'maxpreps_com_runs'
  self.logger = Logger.new(STDOUT)
end
