# US Patents scraping and parsing
**Owner**: Sergii Butrymenko
 
**Scrape instruction**: 
* Patents issued next month after recent in the DB table will be scrapped by default.
* Select run mode with **-s** or **-scrape** -- for scraping, **-p** or **--parse** -- for parsing,  **-sp** or **--scrape_parse** -- for both scraping and parsing.
* Add **-c** or **-continue** parameter to rerun interrupted scraping.
* Specify issue year, month and day with options **--year**, **--month** and **--day** accordingly.
* Specify only selected id in **--list** parameter

**Dataset**:
db01.usa_raw.us_patents%

**Run commands**: 

    bundle exec ruby hamster.rb --grab=36 -s
    bundle exec ruby hamster.rb --grab=36 -s -continue
    bundle exec ruby hamster.rb --grab=36 -parse
    bundle exec ruby hamster.rb --grab=36 -sp
    bundle exec ruby hamster.rb --grab=36 -s --year=2021 --month=3
    bundle exec ruby hamster.rb --grab=36 -s --year=2021 --month=3 --list=23725,23727,23728,23734
    bundle exec ruby hamster.rb --grab=36 -s --year=2021 --month=9 --day=7 --list=5210

_April 2021_
