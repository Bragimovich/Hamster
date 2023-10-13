# frozen_string_literal: true

class MissouriInmateAddresses < ActiveRecord::Base
  establish_connection(Storage[host: :db01 , db: :crime_inmate])
  self.table_name = 'missouri_inmate_addresses'
  self.inheritance_column = :_type_disabled
end
