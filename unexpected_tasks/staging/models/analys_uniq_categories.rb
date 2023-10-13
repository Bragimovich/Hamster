class AnalysUniqCategories < ActiveRecord::Base
  self.table_name = 'litigation_case_type__IRL_unique_categories'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end
