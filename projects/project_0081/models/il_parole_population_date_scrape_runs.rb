# frozen_string_literal: true

class IlParolePopulationDateScrapeRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db15, db: :hle_data])

  self.table_name = 'il_parole_population_date_scrape_runs'
end
