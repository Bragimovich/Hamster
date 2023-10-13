# frozen_string_literal: true

class CountriesSpEn < ActiveRecord::Base
  self.table_name = 'all_countries_sp_en'
  establish_connection(Storage[host: :db02, db: :hle_resources])
end
