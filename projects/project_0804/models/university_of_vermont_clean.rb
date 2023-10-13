class UniversityVermontClean < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :state_salaries__raw])
  include Hamster::Granary

  self.table_name = 'university_of_vermont_payments'
end
