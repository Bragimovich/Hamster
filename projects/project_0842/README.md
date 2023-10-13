**Owner**: Ray Piao
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/842

**Dataset**:

    - db01.crime_inmate.ct_hartfold_arrests
    - db01.crime_inmate.ct_hartfold_bonds
    - db01.crime_inmate.ct_hartfold_holding_facilities
    - db01.crime_inmate.ct_hartfold_holding_facilities_addresses
    - db01.crime_inmate.ct_hartfold_inmate_ids
    - db01.crime_inmate.ct_hartfold_inmate_runs
    - db01.crime_inmate.ct_hartfold_inmates
    - db01.crime_inmate.ct_hartfold_mugshots
    - db01.crime_inmate.ct_hartfold_parole_booking_dates

**Run commands**:
- Ruby
  - bundle exec ruby hamster.rb --grab=0842 --debug [ --buffer=max_buffer_size ]
- Docker
  - hamster grab 842 [ --buffer=max_buffer_size ]

_June 2023_
