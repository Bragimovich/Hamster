# frozen_string_literal: true

class GeneralTmp < ActiveRecord::Base
  self.table_name = 'chicago_crime_statistics_tmp'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
