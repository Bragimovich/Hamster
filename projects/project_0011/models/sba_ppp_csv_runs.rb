# frozen_string_literal: true

class SbaPppCsvRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'sba_ppp_csv_run'
  self.inheritance_column = :_type_disabled
end
