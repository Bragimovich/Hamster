**Owner**: Hassan Nawaz

**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/656

**Dataset**: db01.us_schools_raw.ny_assessment
             db01.us_schools_raw.ny_enrollment
             db01.us_schools_raw.ny_general_info
             db01.us_schools_raw.ny_graduation
             db01.us_schools_raw.ny_runs
             db01.us_schools_raw.ny_safety
             db01.us_schools_raw.ny_assessment_elp
             db01.us_schools_raw.ny_assessment_regents
             db01.us_schools_raw.ny_expenditures
             db01.us_schools_raw.ny_absenteeism
             db01.us_schools_raw.ny_teachers_salaries

**Run commands Ruby**: bundle exec ruby hamster.rb --grab=0656 --debug --download
                     : bundle exec ruby hamster.rb --grab=0656 --debug --store

**Run commands Docker**: hamster grab 656 --download
                       : hamster grab 656 --store

_July 2023_
