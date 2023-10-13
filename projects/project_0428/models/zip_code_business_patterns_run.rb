class ZipCodeBusinessPatternsRuns < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'zip_code_business_patterns_runs'
end
