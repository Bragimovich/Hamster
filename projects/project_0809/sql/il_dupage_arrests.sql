CREATE TABLE IF NOT EXISTS `crime_inmate`.`il_dupage_arrests` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` BIGINT(20) NULL DEFAULT NULL,
  `status` VARCHAR(255) NULL DEFAULT NULL,
  `officer` VARCHAR(255) NULL,
  `arrest_date` DATE NULL DEFAULT NULL,
  `booking_date` DATE NULL DEFAULT NULL,
  `booking_agency` VARCHAR(255) NULL DEFAULT NULL,
  `booking_agency_type` VARCHAR(255) NULL DEFAULT NULL,
  `booking_agency_subtype` VARCHAR(255) NULL DEFAULT NULL,
  `booking_number` VARCHAR(255) NULL DEFAULT NULL,
  `actual_booking_number` VARCHAR(255) NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Azeem Arif',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR (255)GENERATED ALWAYS AS (md5(concat_ws('',status,officer,CAST(arrest_date AS CHAR),CAST(booking_date AS CHAR),booking_agency,booking_agency_type,booking_agency_subtype,booking_number,actual_booking_number,inmate_id))) STORED,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_il_tazewell__arrests_il_tazewell__arrestees_idx` (`inmate_id` ASC),
  CONSTRAINT `fk_il_tazewell__arrests_il_tazewell__arrestees809`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`il_dupage_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
AUTO_INCREMENT = 1385
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Azeem Arif, Task #809';
