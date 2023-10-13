**Owner**: Aleksa Gegic
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/845

**Dataset**: 
  
    - db01.crime_inmate.fl_hillsborough_inmates
    - db01.crime_inmate.fl_hillsborough_inmate_ids
    - db01.crime_inmate.fl_hillsborough_mugshots
    - db01.crime_inmate.fl_hillsborough_arrests
    - db01.crime_inmate.fl_hillsborough_charges
    - db01.crime_inmate.fl_hillsborough_bonds
    - db01.crime_inmate.fl_hillsborough_court_hearings
    - db01.crime_inmate.fl_hillsborough_holding_facilities
    - db01.crime_inmate.fl_hillsborough_inmate_additional_info
    - db01.crime_inmate.fl_hillsborough_charges_additional
    - db01.crime_inmate.fl_hillsborough_inmate_addresses
    - db01.crime_inmate.fl_hillsborough_inmate_aliases

**Run commands**:
- Ruby(options: 'letter' or 'range')
  - bundle exec ruby hamster.rb --grab=0845 --debug --range=a-k
  - bundle exec ruby hamster.rb --grab=0845 --debug --letter=m
- Docker
  - hamster grab 845 --agegic --range=a-k
  - hamster grab 845 --agegic --range=l-z --clone 1

_June 2023_
