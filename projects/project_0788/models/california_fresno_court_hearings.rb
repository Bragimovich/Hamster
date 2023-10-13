# frozen_string_literal: true

class CaliforniaFresnoCourtHearings < ActiveRecord::Base
  establish_connection(Storage[host: :db01 , db: :crime_inmate])
  self.table_name = 'california_fresno_court_hearings'
  self.inheritance_column = :_type_disabled
end
