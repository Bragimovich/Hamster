**Owner**: Maxim G
 
**Scrape instruction**: 

For parsing parties firstly you should download all parties and attorneys:

`hamster --grab=543 --parties_download`

Then you should parse parties and attorneys:

`hamster --grab=543 --parties_parse`

For parsing cases it has two ways. Scrape and parse all cases from each party.

`hamster --grab=543 --cases_download`

We can add parameter instance (--instance=) for choosing court:

- --instance=0 - Supreme Court
- 1 – Court of Appeals 1st District
- 2 – Court of Appeals 2nd District
- ..
- 5 – Court of Appeals 5th District
- 6 – Court of Appeals 6th District

For updating old cases (download new activities or check status) you should use parameter update and choose how many days:

`hamster --grab=543 --update --days=7`


***Finnaly***

Each months you should run this commands for finding new parties and update old with new number of cases.
This parameter concludes all previous commands except update.

```
hamster --grab=543 --parties
```
For updating old cases every week you should run this command

`hamster --grab=543 --update --days=7`


**Dataset**: ...

db01.us_court_cases.fl_saac_case

**Run commands**: ...

_January 2023_
