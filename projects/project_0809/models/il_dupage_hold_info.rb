# frozen_string_literal: true

class IlDupageHoldInfo < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'il_dupage_hold_info'
  self.inheritance_column = :_type_disabled
end
