# frozen_string_literal: true

class CtHartfoldHoldingFacility < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ct_hartfold_holding_facilities'
  self.inheritance_column = :_type_disabled
end
