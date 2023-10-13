use obituary;
CREATE TABLE `tribalarchive_problem_persons`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          VARCHAR(255)       DEFAULT 'processing',
  
  `obituary_id`            BIGINT(20),

  `created_by`      VARCHAR(255)       DEFAULT 'Tribute Archive',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
