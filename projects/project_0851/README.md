**Owner**: Umar Farooq
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/851

**Dataset**: db01.crime_inmate.ct_new_haven_inmates
             db01.crime_inmate.ct_new_haven_runs
             db01.crime_inmate.ct_new_haven_holding_facilities
             db01.crime_inmate.ct_new_haven_inmate_additional_info
             db01.crime_inmate.ct_new_haven_inmate_ids
             db01.crime_inmate.ct_new_haven_inmate_statuses
             db01.crime_inmate.ct_new_haven_parole_booking_dates
             db01.crime_inmate.ct_new_haven_court_hearings  
             db01.crime_inmate.ct_new_haven_charges
             db01.crime_inmate.ct_new_haven_bonds
             db01.crime_inmate.ct_new_haven_arrests                                                                                   

**Run commands**: bundle exec ruby hamster.rb --grab=0851 --debug --download
                  bundle exec ruby hamster.rb --grab=0851 --debug --store

**Run commands Docker**: hamster grab 851 --download
                       : hamster grab 851 --store

_June 2023_
