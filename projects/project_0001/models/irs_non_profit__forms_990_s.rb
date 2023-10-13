class IrsNonProfitForms990s < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :woke_project])
  include Hamster::Granary

  self.table_name = 'irs_non_profit__forms_990_s'
end
