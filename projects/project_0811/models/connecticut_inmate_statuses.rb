# frozen_string_literal: true

class ConInmateStatuses < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :crime_inmate])
    self.table_name = 'connecticut_inmate_statuses'
    self.inheritance_column = :_type_disabled
end
