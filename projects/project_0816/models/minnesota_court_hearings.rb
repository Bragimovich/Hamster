# frozen_string_literal: true

class MinnesotaCourtHearings < ActiveRecord::Base
  establish_connection(Storage[host: :db01 , db: :crime_inmate])
  self.table_name = 'minnesota_court_hearings'
  self.inheritance_column = :_type_disabled
end
