CREATE TABLE `washington_state_campaign_contributions_csv_runs`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `status`          VARCHAR(50)        DEFAULT 'processing',

  `data_source_url` VARCHAR(255)            DEFAULT 'https://data.wa.gov/Politics/Contributions-to-Candidates-and-Political-Committe/kv7h-kjye',
  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX `run_id` (`run_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
