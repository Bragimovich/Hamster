# frozen_string_literal: true
class InmateHearings < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'wa_pierce_court_hearings'
  self.inheritance_column = :_type_disabled
end
