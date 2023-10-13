CREATE TABLE `nv_dropout_rate`
(
  `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `general_id`                BIGINT(20),
  `school_year`               VARCHAR (50),
  `grade`                     VARCHAR (255),
  `dropout_rate`              VARCHAR (255),
  `created_at`                DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_by`                VARCHAR(255)      DEFAULT 'Afia Anwar',
  `deleted`                   BOOLEAN           DEFAULT 0,
  `touched_run_id`            int,
  `data_source_url`           VARCHAR(255)      DEFAULT 'http://nevadareportcard.nv.gov/di/main/cohort4yr',
  `source_updated_date`       DATE, 
  `scrape_frequency`          VARCHAR(255) DEFAULT 'Yearly',
  `md5_hash`                  varchar(255) GENERATED ALWAYS AS (md5(CONCAT_WS('', CAST(general_id as CHAR), school_year, grade, dropout_rate))) STORED,
  `run_id`                    INT,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id_index` (`run_id`),
  INDEX `general_id_index` (`general_id`),
  INDEX `school_year_index` (`school_year`),
  INDEX `deleted_index` (`deleted`)
)DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Afia Anwar, Task #686';
