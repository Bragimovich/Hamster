# frozen_string_literal: true

class IlDupageRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'il_dupage_runs'
  self.inheritance_column = :_type_disabled
end
