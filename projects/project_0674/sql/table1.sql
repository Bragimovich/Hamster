CREATE TABLE `raw_ca__contra_costa_county_inmates__arrests`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  # any columns
  `name`            VARCHAR(255),
  `race`            VARCHAR(50),
  `date_of_birth`   DATE,
  `gen`             VARCHAR(50),
  `height`          VARCHAR(50),
  `weight`          VARCHAR(50),
  `hair`            VARCHAR(50),
  `eyes`            VARCHAR(50),
  `job_description`   VARCHAR(255),
  `arrest_date_time`  VARCHAR(50),
  `release_date`      DATE,
  `booking_num`       VARCHAR(50),
  `book_date_time`    VARCHAR(50),
  `arrest_location`   VARCHAR(255),
  `bail_amout`       VARCHAR(50),
  `rel_type`         VARCHAR(255),
 
 
  `created_by`       VARCHAR(255)      DEFAULT 'Scraper name',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Mashal Ahmad ';
