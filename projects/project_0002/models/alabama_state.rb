class AlabamaState < ActiveRecord::Base
  ActiveRecord::Base.establish_connection(Storage[host: :db13, db: :usa_raw])
  self.table_name="alabama_business_licenses_temp_temp"
  self.inheritance_column = :_type_disabled
end
