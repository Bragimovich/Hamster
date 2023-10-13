# frozen_string_literal: true

class MissouriMugshots < ActiveRecord::Base
  establish_connection(Storage[host: :db01 , db: :crime_inmate])
  self.table_name = 'missouri_mugshots'
  self.inheritance_column = :_type_disabled
end
