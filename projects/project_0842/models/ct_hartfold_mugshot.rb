# frozen_string_literal: true

class CtHartfoldMugshot < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ct_hartfold_mugshots'
  self.inheritance_column = :_type_disabled
end
