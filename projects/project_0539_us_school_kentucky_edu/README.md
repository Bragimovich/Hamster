**Owner**: Frank Rao
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/539

**Dataset**: 
- DB01.us_schools_raw.ky_administrators
- DB01.us_schools_raw.ky_assesment_national
- DB01.us_schools_raw.ky_assessment_act
- DB01.us_schools_raw.ky_enrollment
- DB01.us_schools_raw.ky_general_info
- DB01.us_schools_raw.ky_graduation_rate
- DB01.us_schools_raw.ky_safety_audit
- DB01.us_schools_raw.ky_safety_climate
- DB01.us_schools_raw.ky_safety_climate_index
- DB01.us_schools_raw.ky_safety_events
- DB01.us_schools_raw.ky_schools_assessment
- DB01.us_schools_raw.ky_schools_assessment_by_levels

**Run commands**: hamster grab 539 --debug
ruby hamster.rb --grab=539 --debug --download
ruby hamster.rb --grab=539 --debug --store --year=2022
nohup ruby hamster.rb --grab=539 --debug --store --year=2021 &
nohup ruby hamster.rb --grab=539 --debug --store --year=2020 > nohup2020.out 2>&1 &