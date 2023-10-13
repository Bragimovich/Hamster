# frozen_string_literal: true

class CpiInflationRun < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  self.table_name = 'cpi_inflation_runs'
  self.inheritance_column = :_type_disabled
end
 