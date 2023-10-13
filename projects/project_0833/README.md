**Owner**: Aleksa Gegic
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/833

**Dataset**: 
    - db01.crime_inmate.wa_snohomish_inmates
    - db01.crime_inmate.wa_snohomish_inmate_ids
    - db01.crime_inmate.wa_snohomish_arrests
    - db01.crime_inmate.wa_snohomish_charges
    - db01.crime_inmate.wa_snohomish_bonds
    - db01.crime_inmate.wa_snohomish_court_hearings
    - db01.crime_inmate.wa_snohomish_holding_facilities
    - db01.crime_inmate.wa_snohomish_inmate_additional_info
    - db01.crime_inmate.wa_snohomish_inmate_statuses
    - db01.crime_inmate.wa_snohomish_charges_additional

**Run commands**:
- Ruby
  - bundle exec ruby hamster.rb --grab=0833 --debug
- Docker
  - hamster grab 833 --agegic

_June 2023_
