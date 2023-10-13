CREATE TABLE `congressional_record_journals`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `record_link`     VARCHAR(255),
  `journal`         VARCHAR(255),
  `section`         VARCHAR(255),
  `pages`           VARCHAR(255),
  `title`           VARCHAR(255),
  `date`            DATETIME,
  `text`            TEXT,

  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
