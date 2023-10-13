# frozen_string_literal: true

class CtHartfoldBond < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ct_hartfold_bonds'
  self.inheritance_column = :_type_disabled
end
