# frozen_string_literal: true
class NmBernalilloInmateAddresses < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'nm_bernalillo_inmate_addresses'
  self.inheritance_column = :_type_disabled
end
