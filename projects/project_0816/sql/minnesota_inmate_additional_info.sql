CREATE TABLE IF NOT EXISTS `crime_inmate`.`minnesota_inmate_additional_info` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` BIGINT(20) NULL DEFAULT NULL,
  `current_status` VARCHAR(255) NULL DEFAULT NULL,
  `current_location` VARCHAR(255) NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Mariam',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash`  VARCHAR (255)GENERATED ALWAYS AS (md5(concat_ws('',current_location,inmate_id))) STORED,
  INDEX `fk_immate_additional_info_immates1_idx` (`inmate_id` ASC),
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  CONSTRAINT `fk_immate_additional_info_immates816`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`minnesota_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci;
