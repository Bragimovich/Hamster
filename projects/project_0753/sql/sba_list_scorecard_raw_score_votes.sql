CREATE TABLE `sba_list_scorecard_raw_score_votes`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `person_id`       int,
  `vote_date`       DATE                 DEFAULT NULL,
  `congress_number` int                  DEFAULT NULL,
  `vote_name`       VARCHAR(511)         DEFAULT NULL,
  `vote_desc`       VARCHAR(511)         DEFAULT NULL,
  `score`           BOOLEAN              DEFAULT NULL,
  `rl_link`         VARCHAR(511)         DEFAULT NULL,
  `pr_link`         VARCHAR(511)         DEFAULT NULL,
  `past`            BOOLEAN              DEFAULT NULL,
  `data_source_url` VARCHAR(255)         DEFAULT NULL,
  `created_by`      VARCHAR(255)      DEFAULT 'Afia',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`       varchar(255) GENERATED ALWAYS AS (md5(CONCAT_WS('', CAST(person_id as CHAR), CAST(vote_date as CHAR), CAST(congress_number as CHAR), vote_name, vote_desc, CAST(score as CHAR), rl_link, pr_link, CAST(past as CHAR)))) STORED UNIQUE KEY,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci,
COMMENT = 'Created by Afia, Task #753';
