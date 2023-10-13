**Owner**: Aleksa Gegic
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/818

**Dataset**: 

    - db01.crime_inmate.mississippi_inmates
    - db01.crime_inmate.mississippi_inmate_ids
    - db01.crime_inmate.mississippi_inmate_additional_info
    - db01.crime_inmate.mississippi_physical_location_histories
    - db01.crime_inmate.mississippi_mugshots
    - db01.crime_inmate.mississippi_arrests
    - db01.crime_inmate.mississippi_charges
    - db01.crime_inmate.mississippi_court_addresses
    - db01.crime_inmate.mississippi_court_hearings
    - db01.crime_inmate.mississippi_holding_facilities

**Run commands**:
- Ruby
  - bundle exec ruby hamster.rb --grab=0818 --blcok=first --debug
  - bundle exec ruby hamster.rb --grab=0818 --block=second --debug
- Docker
  - hamster grab 818 --agegic --block=first
  - hamster grab 818 --agegic --block=second --clone 1

_June 2023_
