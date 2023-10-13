class MsMississippiBar < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :lawyer_status])
  include Hamster::Granary

  self.table_name = 'ms_mississippi_bar'
  self.logger = Logger.new(STDOUT)
end
