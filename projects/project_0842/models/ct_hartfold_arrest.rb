# frozen_string_literal: true

class CtHartfoldArrest < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ct_hartfold_arrests'
  self.inheritance_column = :_type_disabled
end
