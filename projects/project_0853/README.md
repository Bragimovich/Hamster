**Owner**: Aleksa Gegic
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/853

**Dataset**: 
  
    - db01.crime_inmate.al_inmates
    - db01.crime_inmate.al_inmate_aliases
    - db01.crime_inmate.al_inmate_ids
    - db01.crime_inmate.al_inmate_statuses
    - db01.crime_inmate.al_mugshots
    - db01.crime_inmate.al_custody_levels
    - db01.crime_inmate.al_inmate_additional_info
    - db01.crime_inmate.al_arrests
    - db01.crime_inmate.al_charges
    - db01.crime_inmate.al_court_addresses
    - db01.crime_inmate.al_court_hearings
    - db01.crime_inmate.al_court_hearings_additional
    - db01.crime_inmate.al_holding_facilities
    - db01.crime_inmate.al_holding_facilities_additional

**Run commands**:
- Ruby
  - bundle exec ruby hamster.rb --grab=0853 --debug
  - bundle exec ruby hamster.rb --grab=0853 --range=a-f --debug
  - bundle exec ruby hamster.rb --grab=0853 --letter=k --debug
- Docker
  - hamster grab 853 --agegic --letter=j
  - hamster grab 853 --agegic --range=a-k
  - hamster grab 853 --agegic --range=l-z --clone 1

_June 2023_
