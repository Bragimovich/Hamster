# frozen_string_literal: true

class General < ActiveRecord::Base
  self.table_name = 'chicago_crime_statistics'
  establish_connection(Storage[host: :db01, db: :usa_raw])
end
