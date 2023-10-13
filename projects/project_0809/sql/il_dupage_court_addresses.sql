CREATE TABLE IF NOT EXISTS `crime_inmate`.`il_dupage_court_addresses` (
  `court_id` BIGINT(20) NOT NULL,
  `full_address` VARCHAR(255) NULL DEFAULT NULL,
  `street_address` VARCHAR(255) NULL DEFAULT NULL,
  `city` VARCHAR(255) NULL DEFAULT NULL,
  `county` VARCHAR(255) NULL DEFAULT NULL,
  `state` VARCHAR(255) NULL DEFAULT NULL,
  `zip` VARCHAR(255) NULL DEFAULT NULL,
  `lan` VARCHAR(255) NULL DEFAULT NULL,
  `lon` VARCHAR(255) NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Azeem Arif',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR (255)GENERATED ALWAYS AS (md5(concat_ws('',full_address,street_address,city,county,state,zip,lan,lon))) STORED,
  PRIMARY KEY (`court_id`))
ENGINE = InnoDB
COMMENT = 'Created by Azeem Arif, Task #809';
