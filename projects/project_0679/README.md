**Owner**: Umar Farooq

**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/679

**Dataset**: db01.us_schools_raw.ak_assessment
             db01.us_schools_raw.ak_enrollment
             db01.us_schools_raw.ak_general_info
             db01.us_schools_raw.ak_graduation
             db01.us_schools_raw.ak_revenue
             db01.us_schools_raw.ak_runs
             db01.us_schools_raw.ak_teacher_counts

**Run commands Ruby**: bundle exec ruby hamster.rb --grab=0679 --debug --download
                     : bundle exec ruby hamster.rb --grab=0679 --debug --store

**Run commands Docker**: hamster grab 679 --download
                       : hamster grab 679 --store

_April_ 2023_
