class InsuranceStateData < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'fl_hurricane_insurance__state_data'
  self.inheritance_column = :_type_disabled
end
