**Owner**: Aleksa Gegic
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/873

**Dataset**: 
  
    - db01.crime_inmate.nj_doc_inmates
    - db01.crime_inmate.nj_doc_inmate_ids
    - db01.crime_inmate.nj_doc_inmate_additional_info
    - db01.crime_inmate.nj_doc_inmate_aliases
    - db01.crime_inmate.nj_doc_mugshots
    - db01.crime_inmate.nj_doc_arrests
    - db01.crime_inmate.nj_doc_charges
    - db01.crime_inmate.nj_doc_court_addresses
    - db01.crime_inmate.nj_doc_court_hearings
    - db01.crime_inmate.nj_doc_holding_facilities
    - db01.crime_inmate.nj_doc_parole_booking_dates

**Run commands**:
- Ruby
  - bundle exec ruby hamster.rb --grab=0873 --debug
  - bundle exec ruby hamster.rb --grab=0873 --range=a-f --debug
  - bundle exec ruby hamster.rb --grab=0873 --letter=k --debug
- Docker
  - hamster grab 873 --agegic --range=a-k
  - hamster grab 873 --agegic --range=l-z --clone 1

_June 2023_
