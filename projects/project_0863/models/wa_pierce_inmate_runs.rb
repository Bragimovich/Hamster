# frozen_string_literal: true
class InmateRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'wa_pierce_inmate_runs'
  self.inheritance_column = :_type_disabled
end
