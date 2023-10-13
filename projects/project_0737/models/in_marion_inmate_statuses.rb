# frozen_string_literal: true
class InMarionInmateStatuses < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'in_marion_inmate_statuses'
  self.inheritance_column = :_type_disabled
end
