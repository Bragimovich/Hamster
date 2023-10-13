# frozen_string_literal: true

class CaliforniaFresnoInmateIds < ActiveRecord::Base
  establish_connection(Storage[host: :db01 , db: :crime_inmate])
  self.table_name = 'california_fresno_inmate_ids'
  self.inheritance_column = :_type_disabled
end
