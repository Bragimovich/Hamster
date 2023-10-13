# frozen_string_literal: true

class CtHartfoldInmateRun < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :crime_inmate])
  self.table_name = 'ct_hartfold_inmate_runs'
  self.inheritance_column = :_type_disabled
end
