**Owner**: Aleksa Gegic
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/890

**Dataset**: 
  
    - db01.us_schools_raw.nc_general_info
    - db01.us_schools_raw.nc_assessment
    - db01.us_schools_raw.nc_assessment_act
    - db01.us_schools_raw.nc_assessment_ap_sat
    - db01.us_schools_raw.nc_finaces_expenditures
    - db01.us_schools_raw.nc_finances_salaries

**Run commands**:
- Ruby
  - bundle exec ruby hamster.rb --grab=0890 --debug
- Docker
  - hamster grab 0890 --agegic

_July 2023_
