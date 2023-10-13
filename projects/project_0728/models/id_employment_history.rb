class IdEmploymentHistory < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  include Hamster::Granary

  self.table_name = 'id_employment_history'
  self.logger = Logger.new(STDOUT)
end

