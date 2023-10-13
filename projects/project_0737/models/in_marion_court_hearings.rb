# frozen_string_literal: true
class InMarionCourtHearings < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'in_marion_court_hearings'
  self.inheritance_column = :_type_disabled
end
