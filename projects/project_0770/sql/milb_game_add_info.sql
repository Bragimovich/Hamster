CREATE TABLE `milb_game_add_info`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `mlb_game_id`     BIGINT,
  `game_duration`   VARCHAR(255),
  `attendance`      INT,
  `weather`         VARCHAR(255),
  `wind`            VARCHAR(255),
  `first_pitch`     VARCHAR(255),
  `umpires`         VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Ray Piao',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Ray Piao';
