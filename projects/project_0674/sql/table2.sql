CREATE TABLE `raw_ca__contra_costa_county_inmates__arrests_charges`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  # any columns
  `arrest_id`       INT(8),
  `arrest_type`     VARCHAR(50),
  `charge`          VARCHAR(50),
  `charge_description`  VARCHAR(255),

  `created_by`      VARCHAR(255)      DEFAULT 'Scraper name',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Mashal Ahmad ';
