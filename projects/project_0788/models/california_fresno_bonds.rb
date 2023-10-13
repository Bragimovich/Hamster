# frozen_string_literal: true

class CaliforniaFresnoBonds < ActiveRecord::Base
  establish_connection(Storage[host: :db01 , db: :crime_inmate])
  self.table_name = 'california_fresno_bonds'
  self.inheritance_column = :_type_disabled
end
