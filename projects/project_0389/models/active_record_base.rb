class ActiveRecordBase < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.abstract_class     = true
  self.inheritance_column = :_type_disabled
  include Hamster::Loggable
  include Hamster::Granary
end

