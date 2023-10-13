class CdcCovid < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: 'usa_raw'])
  self.table_name = 'cdc_covid_19_case_surveillance'
  self.inheritance_column = :_type_disabled
end
