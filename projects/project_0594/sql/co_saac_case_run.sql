CREATE TABLE co_saac_case_run
(
  id            BIGINT(20) AUTO_INCREMENT     PRIMARY KEY,
	status        VARCHAR(255)                  DEFAULT 'processing',
  created_by    VARCHAR(255)                  DEFAULT 'Robert Arnold',
  created_at    DATETIME                      DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL             DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY id (id)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Table for table from task 594. Made by Robert A.';
