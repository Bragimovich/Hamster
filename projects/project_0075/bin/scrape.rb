# frozen_string_literal: true
# Owner: Seth Putz

# Scrape instruction: Create table db01.usa_raw.building_permits_by_county with all columns we have in csv files + all regular internal columns (like scraper name, etc.)

# Dataset: db01.usa_raw.building_permits_by_county

# Run commands:
## bundle exec ruby hamster.rb --grab=0075 --download
## bundle exec ruby hamster.rb --grab=0075 --store
## bundle exec ruby hamster.rb --grab=0075 --update (runs both download and store)

# Date: December 2022

require_relative '../lib/manager'

def scrape(options)
  manager = BuildingPermitsManager.new

  if options[:download].present?
    manager.start_download
    report(to: 'seth.putz', message: "#0075: Download finished.", use: :slack)
  elsif options[:store]
    manager.start_store
    report(to: 'seth.putz', message: "#0075: Store finished.", use: :slack)
  else
    manager.start_cron_update
    report(to: 'seth.putz', message: "#0075: Cron Update finished.", use: :slack)
  end
end