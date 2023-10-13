**Owner**: Ray Piao
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/770

**Dataset**:

    - db02.us_sports_milb_raw.milb_teams
    - db02.us_sports_milb_raw.milb_people
    - db02.us_sports_milb_raw.milb_roster
    - db02.us_sports_milb_raw.milb_career_stats
    - db02.us_sports_milb_raw.milb_team_transactions
    - db02.us_sports_milb_raw.milb_games
    - db02.us_sports_milb_raw.milb_score_by_innings
    - db02.us_sports_milb_raw.milb_batters_stats
    - db02.us_sports_milb_raw.milb_pitchers_stats
    - db02.us_sports_milb_raw.milb_game_add_info

**Run commands**:
- Ruby
  - bundle exec ruby hamster.rb --grab=0770 --debug [ --people ] [ --transactions ] [ --games ] [ --history ] [ --limit ] [ --buffer=max_buffer_size ] [ --skipteams=comma_separated_team_slugs ] [ --skipdelete ]
- Docker
  - hamster grab 770 [ --people ] [ --transactions ] [ --games ] [ --history ] [ --limit ] [ --buffer=max_buffer_size ] [ --skipteams=comma_separated_team_slugs ] [ --skipdelete ]

_May 2023_
