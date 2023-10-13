CREATE TABLE `il_dupage__arrestees`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `full_name`       VARCHAR(255),
  `first_name`      VARCHAR(255),
  `middle_name`     VARCHAR(255),
  `last_name`       VARCHAR(255),
  `suffix`          VARCHAR(255),
  `birthdate`       DATE,
  `age`             INT,
  `age_as_of_date`  INT,
  `race`            VARCHAR(255),
  `sex`             VARCHAR(5),
  `height`          VARCHAR(255),
  `weight`          VARCHAR(255),
  `mugshot`         VARCHAR(1024),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Scraper name',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY        `md5` (`md5_hash`),
  INDEX             `run_id` (`run_id`),
  INDEX             `touched_run_id` (`touched_run_id`),
  INDEX             `deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Alim L.';
