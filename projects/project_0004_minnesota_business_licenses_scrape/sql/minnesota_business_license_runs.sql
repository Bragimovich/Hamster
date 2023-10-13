CREATE TABLE minnesota_business_license_runs
(
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  status          VARCHAR(255)       DEFAULT 'processing',
  created_by      VARCHAR(255)       DEFAULT 'Art Jarocki',
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX status_idx (status)
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;
