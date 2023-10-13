**Owner**: Muhammad Qasim
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/723

**Dataset**:  db02.us_sports_raw.schools,
              db02.us_sports_raw.persons,
              db02.us_sports_raw.contacts,
              db02.us_sports_raw.run,
              db02.us_sports_raw.games,
              db02.us_sports_raw.final_result_scores_players,
              db02.us_sports_raw.final_result_score_details,
              db02.us_sports_raw.final_result_score_by_innings,
              db02.us_sports_raw.final_result_additions_desc,

**Run commands**:  hamster grab 723 --mqasim --download
                   hamster grab 723 --mqasim --store
                   hamster grab 723 --mqasim --relation
                   hamster grab 723 --mqasim --games_update
                   hamster grab 723 --mqasim --alias
