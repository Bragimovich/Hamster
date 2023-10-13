class AnalysKeywordRawType < ActiveRecord::Base
  self.table_name = 'us_case_keyword_to_unique_raw_type_category'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end
