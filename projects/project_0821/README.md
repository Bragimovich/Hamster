**Owner**: Aleksa Gegic
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/21

**Dataset**: 
  
    - db01.crime_inmate.tx_fort_bend_inmates
    - db01.crime_inmate.tx_fort_bend_inmate_ids
    - db01.crime_inmate.tx_fort_bend_inmate_additional_info
    - db01.crime_inmate.tx_fort_bend_mugshots
    - db01.crime_inmate.tx_fort_bend_arrests
    - db01.crime_inmate.tx_fort_bend_charges
    - db01.crime_inmate.tx_fort_bend_charge_additionals
    - db01.crime_inmate.tx_fort_bend_bonds

**Run commands**:
- Ruby
  - bundle exec ruby hamster.rb --grab=0821 --debug
- Docker
  - hamster grab 821 --agegic

_June 2023_
