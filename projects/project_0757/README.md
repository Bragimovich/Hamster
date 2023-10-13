**Owner**: Danil Kurshanov
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/757

**Dataset**:

    - db01.usa_raw.fdic_bank_failures
    - db01.usa_raw.fdic_bank_runs

**Run commands**: 
- Ruby (Only local)
    - bundle exec ruby hamster.rb --grab=0757 --debug --download # Download html_page and CSV file in "#{storehouse}/store/.."
    - bundle exec ruby hamster.rb --grab=0757 --debug --store    # Parse data
- Docker
    - hamster grab 757 --download
    - hamster grab 757 --store

**Description**:

Monthly downloads a CSV table with data and adds new data to the DB

_May 2023_
