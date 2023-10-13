# frozen_string_literal: true

class IlPrisonPopulationDataScrape < ActiveRecord::Base
  establish_connection(Storage[host: :db15, db: :hle_data])

  self.table_name = 'il_prison_population_data_scrape'
end
