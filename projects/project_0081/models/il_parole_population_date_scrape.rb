# frozen_string_literal: true

class IlParolePopulationDateScrape < ActiveRecord::Base
  establish_connection(Storage[host: :db15, db: :hle_data])

  self.table_name = 'il_parole_population_date_scrape'
end
