**Owner**: Aleksa Gegic
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/743

**Dataset**: 

    - db01.crime_inmate.al_inmates
    - db01.crime_inmate.al_inmate_aliases
    - db01.crime_inmate.al_inmate_ids
    - db01.crime_inmate.al_inmate_statuses
    - db01.crime_inmate.al_mugshots
    - db01.crime_inmate.al_custody_levels
    - db01.crime_inmate.al_inmate_additional_info

**Run commands**:
  - Ruby
    - bundle exec ruby hamster.rb --grab=0743 --debug
  - Docker
    - hamster grab 743 --agegic

_August 2023_
