# frozen_string_literal: true
class GaGwinnettRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ga_gwinnett_runs'
  self.inheritance_column = :_type_disabled
end
