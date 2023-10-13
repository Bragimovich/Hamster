CREATE TABLE IF NOT EXISTS `crime_inmate`.`ut_utah_inmate_additional_info` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `immate_id` BIGINT(20) NULL DEFAULT NULL,
  `height` VARCHAR(255) NULL DEFAULT NULL,
  `weight` VARCHAR(255) NULL DEFAULT NULL,
  `hair_color` VARCHAR(255) NULL DEFAULT NULL,
  `eye_color` VARCHAR(255) NULL DEFAULT NULL,
  `street_address` VARCHAR(255) NULL DEFAULT NULL,
  `age` INT(11) NULL DEFAULT NULL,
  `age_as_of_date` INT(11) NULL DEFAULT NULL,
  `complexion` VARCHAR(255) NULL DEFAULT NULL,
  `build` VARCHAR(255) NULL DEFAULT NULL,
  `risk_level` VARCHAR(255) NULL DEFAULT NULL,
  `visitation_status` VARCHAR(255) NULL DEFAULT NULL,
  `body_modification_raw` VARCHAR(255) NULL DEFAULT NULL,
  `scars` VARCHAR(255) NULL DEFAULT NULL,
  `marks` VARCHAR(255) NULL DEFAULT NULL,
  `tattoos` VARCHAR(255) NULL DEFAULT NULL,
  `current_location` VARCHAR(255) NULL DEFAULT NULL,
  `work_or_program_participation` VARCHAR(255) NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Muhammad Musa',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  `hair_length` VARCHAR(45) NULL,
  `ethnicity` VARCHAR(45) NULL,
  `marital_status` VARCHAR(45) NULL,
  `citizen` VARCHAR(45) NULL,
  `county_of_bith` VARCHAR(45) NULL,
  INDEX `fk_immate_additional_info_immates1_idx` (`immate_id` ASC),
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),

  CONSTRAINT `fk_immate_additional_info_immates814`
    FOREIGN KEY (`immate_id`)
    REFERENCES `crime_inmate`.`ut_utah_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Muhammad Musa, Task #814';
