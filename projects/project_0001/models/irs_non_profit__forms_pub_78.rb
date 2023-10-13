class IrsNonProfitFormsPub78 < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :woke_project])
  include Hamster::Granary

  self.table_name = 'irs_non_profit__forms_pub_78'
end
