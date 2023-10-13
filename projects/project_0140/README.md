**Owner**: Adeel
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/140

**Dataset**:      db01.usa_raw.public_companies_stock_ft_com_equities_info
                  db01.usa_raw.public_companies_stock_ft_com_equities_prices
                  db01.usa_raw.public_companies_stock_ft_com_equities

**Run commands**: hamster grab 140 --download_info
                  hamster grab 140 --clone 1 --download_price
                  hamster grab 140 --clone 2 --download_equities
                  hamster grab 140 --clone 3 --store
                  hamster grab 140 --clone 4 --store_equities

_September 2022_
