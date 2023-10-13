CREATE TABLE `california_fresno_arrests` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `immate_id` BIGINT(20) NULL DEFAULT NULL,
  `status` VARCHAR(255) NULL DEFAULT NULL,
  `officer` VARCHAR(255) NULL,
  `arrest_date` DATETIME NULL DEFAULT NULL,
  `booking_date` DATETIME NULL DEFAULT NULL,
  `booking_agency` VARCHAR(255) NULL DEFAULT NULL,
  `booking_agency_type` VARCHAR(255) NULL DEFAULT NULL,
  `booking_agency_subtype` VARCHAR(255) NULL DEFAULT NULL,
  `booking_number` VARCHAR(255) NULL DEFAULT NULL,
  `actual_booking_number` VARCHAR(255) NULL,
  `full_address`  VARCHAR(255) DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Usman',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC) ,
  INDEX `run_id` (`run_id` ASC) ,
  INDEX `touched_run_id` (`touched_run_id` ASC) ,
  INDEX `deleted` (`deleted` ASC) ,
  INDEX `fk_il_tazewell__arrests_il_tazewell__arrestees_idx` (`immate_id` ASC) ,
  CONSTRAINT `fk_il_tazewell__arrests_il_tazewell__arrestees5`
    FOREIGN KEY (`immate_id`)
    REFERENCES `crime_inmate`.`california_fresno_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
AUTO_INCREMENT = 1385
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Muhammad Usman, Task #0788';
