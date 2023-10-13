class MaxprepsComRosters < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db02, db: :limpar_maxpreps_com])
  include Hamster::Granary

  self.table_name = 'maxpreps_com_rosters'
  self.logger = Logger.new(STDOUT)
end
