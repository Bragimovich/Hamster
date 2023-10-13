# frozen_string_literal: true

class CmsGovCovidVaxRateV2 < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw])
  include Hamster::Granary
  self.table_name = 'cms_gov_covid_vax_rates_v2'
end
