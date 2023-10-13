CREATE TABLE `milb_roster`
(
  `id`            BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `mlb_team_id`   BIGINT,
  `mlb_person_id` BIGINT,
  `season`        VARCHAR(255),
  `created_by`    VARCHAR(255)      DEFAULT 'Ray Piao',
  `created_at`    DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `md5_hash`      VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Ray Piao';
