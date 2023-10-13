CREATE TABLE `hs_athlete_twitter_announcements`
(
  `id`                              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                          BIGINT(20),
  `athlete_id`                      varchar(500),
  `first_name`	                    varchar(500),
  `last_name`	                    varchar(500),
  `players_limpar_uuid`             varchar(500),
  `high_school`	                    varchar(500),
  `link_to_tweet_with_announcement`	varchar(500),
  `announcement_type`               varchar(500),
  `to_what_university`              varchar(500),
  `team_limpar_uuid`                varchar(500),
  `twitter_date`                    varchar(500),
  `twitter_embed_code`              TEXT,
  `created_at`	    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_by`      VARCHAR(255)      DEFAULT 'Halid Ibragimov',
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Halid Ibragimov';
