# frozen_string_literal: true

class NorthCarolinaBusinessLicensesNewBusinessCsvTemp < ActiveRecord::Base
  self.table_name = 'north_carolina_business_licenses_new_business_csv_temp'
  establish_connection(Storage[host: :db13, db: :usa_raw])
  self.inheritance_column = :_type_disabled
end
