**Owner**: Hassan Nawaz

**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/836

**Dataset**: db01.crime_inmate.fl_palmbeach_arrests
             db01.crime_inmate.fl_palmbeach_bonds
             db01.crime_inmate.fl_palmbeach_charges
             db01.crime_inmate.fl_palmbeach_holding_facilities
             db01.crime_inmate.fl_palmbeach_inmate_additional_info
             db01.crime_inmate.fl_palmbeach_inmate_addresses
             db01.crime_inmate.fl_palmbeach_inmate_ids
             db01.crime_inmate.fl_palmbeach_inmates
             db01.crime_inmate.fl_palmbeach_mugshots
             db01.crime_inmate.fl_palmbeach_runs

**Run commands Ruby**: bundle exec ruby hamster.rb --grab=0836 --debug --download
                     : bundle exec ruby hamster.rb --grab=0836 --debug --store

**Run commands Docker**: hamster grab 836 --download
                       : hamster grab 836 --store

_June 2023_
