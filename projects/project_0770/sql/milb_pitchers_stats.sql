CREATE TABLE `milb_pitchers_stats`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `mlb_game_id`     BIGINT,
  `roster_hash`     VARCHAR(255),
  `note`            VARCHAR(255),
  `innings_pitched` FLOAT,
  `hits`            INT,
  `runs`            INT,
  `earned_runs`     INT,
  `base_on_balls`   INT,
  `strike_outs`     INT,
  `home_runs`       INT,
  `era`             FLOAT,
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Ray Piao',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Ray Piao';
