class EqutiesRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'equties_ft_runs'
  self.inheritance_column = :_type_disabled
end
