**Owner**: Ray Piao

**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/484

**Dataset**:

    - db01.re_sales.remax_home_listings
    - db01.re_sales.remax_home_listings_property_history

**Run commands**:
- Ruby
  - bundle exec ruby hamster.rb --grab=0484 --debug [ --buffer=max_buffer_size ] [ --master ] [ --slave=slave_number ] [ --skipdelete ]
- Docker
  - hamster grab 484 [ --buffer=max_buffer_size ] [ --master ] [ --slave=slave_number ] [ --skipdelete ]

_June 2023_
