# frozen_string_literal: true

class ConCourtHearings < ActiveRecord::Base
    establish_connection(Storage[host: :db01, db: :crime_inmate])
    self.table_name = 'connecticut_court_hearings'
    self.inheritance_column = :_type_disabled
end
