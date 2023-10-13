# frozen_string_literal: true

class IlDupageCourtAddresses < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'il_dupage_court_addresses'
  self.inheritance_column = :_type_disabled
end
