class AnalysLitigationTotals < ActiveRecord::Base
  self.table_name = 'litigation_totals'
  self.inheritance_column = :_type_disabled
  establish_connection(Storage[host: :db01, db: :us_courts_analysis])
end
