# frozen_string_literal: true

class AzEsaReportsQuarterly < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_schools_raw])
  self.table_name = 'az_esa_reports_quarterly'
  self.inheritance_column = :_type_disabled
  self.logger = Logger.new($stdout)
end
