CREATE TABLE `raw_tx__harris_county_texas_sheriff_office_immates`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  `name`	        varchar(255),
  `date_arrested`	varchar(50),
  `charge`	        text,
  `race`	        varchar(50),
  `sex`	            varchar(50),
  `arrest_location`	varchar(255),
  `created_at`	    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_by`      VARCHAR(255)      DEFAULT 'Halid Ibragimov',
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Halid Ibragimov';
