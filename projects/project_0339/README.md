**Owner**: Anton S
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/339

**Dataset**: db13.usa_raw.north_carolina_business_licenses

**Run commands**: bundle exec ruby hamster.rb --grab=339 --download

_February 2022_

#### Upload CSV files
`docker cp /home/developer/Downloads/north_carolina_business_licenses_new_business_csv_2022-11-03/2006-01-01_2008-01-01.csv hamster-cp:/home/hamster/HarvestStorehouse/project_0339/tmp/2006-01-01_2008-01-01.csv`

`hamster grab 339 --upload_csv_data --csv_file_path='/home/hamster/HarvestStorehouse/project_0339/tmp/1990-01-01_1992-01-01.csv'`