CREATE TABLE `chicago_crime_statistics`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  # BEGIN scrape 77
    `id_court` BIGINT,
    `case_number` VARCHAR(20),
    `date_court`  datetime,
    `block` varchar(255),
    `iucr` varchar(10),
    `primary_type` TEXT,
    `description` text,
    `location_desc` text,
    `arrest` VARCHAR(10),
    `domestic` VARCHAR(10),
    `beat` INT,
    `distrinct` INT,
    `ward` INT,
    `community_area` INT,
    `fbi_code` VARCHAR(10),
    `x_coordinate` VARCHAR(50),
    `y_coordinate` VARCHAR(50),
    `year` YEAR,
    `update_on` DATETIME,
    `latitude` varchar(50),
    `longitude` varchar(50),
    `location` varchar(100),
  # END
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)       DEFAULT 'Mikhail Golovanov',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN            DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;


CREATE TABLE `chicago_crime_statistics_runs`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `status`      varchar(255) DEFAULT  'processing',
    `created_by`      VARCHAR(255)       DEFAULT 'Mikhail Golovanov',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;


