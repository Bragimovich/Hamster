**Owner**: Muhammad Habib

**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/800

**Dataset**: db01.crime_inmate.maryland_inmates
             db01.crime_inmate.maryland_inmate_ids
             db01.crime_inmate.maryland_inmate_ids_additional
             db01.crime_inmate.maryland_holding_facilities_addresses
             db01.crime_inmate.maryland_holding_facilities_additional
             db01.crime_inmate.maryland_holding_facilities
             db01.crime_inmate.maryland_inmates_runs

**Run commands Ruby**: bundle exec ruby hamster.rb --grab=0800 --debug --download
                     : bundle exec ruby hamster.rb --grab=0800 --debug --store

**Run commands Docker**: hamster grab 800 --download
                       : hamster grab 800 --store

_June_ 2023_
