# frozen_string_literal: true
class FlPolkRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'fl_polk_runs'
  self.inheritance_column = :_type_disabled
end
