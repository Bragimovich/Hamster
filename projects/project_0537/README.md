**Owner**: Danil Kurshanov
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/537

**Dataset**:

    - db01.us_schools_raw.in_general_info
    - db01.us_schools_raw.in_administrators
    - db01.us_schools_raw.in_enrollment_by_grade
    - db01.us_schools_raw.in_enrollment_by_ethnicity
    - db01.us_schools_raw.in_enrollment_by_meal_status
    - db01.us_schools_raw.in_enrollment_by_special_edu_and_ell
    - db01.us_schools_raw.in_schools_assessment
    - db01.us_schools_raw.in_schools_assessment_by_levels
    - db01.us_schools_raw.in_schools_sat

**Run commands**:

- Ruby (Only local)
    - bundle exec ruby hamster.rb --grab=0537 --debug --download # Download all xlsx fables and safe in "#{storehouse}/store/.."
    - bundle exec ruby hamster.rb --grab=0537 --debug --store    # Parse xlsx fables file
- Docker
    - hamster grab 537 --download
    - hamster grab 537 --store

**Description**:

The frequency of updating data is not defined, but at least once a year you need to manually check for new data. 
If no new data arrives before July, you need to check at least once a month.

On July 1, the script will send a notification about the verification of new data. Change developer Slack ID to 
manager.send_slack_message method.

_March 2023_
