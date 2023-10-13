CREATE TABLE IF NOT EXISTS `crime_inmate`.`ct_new_haven_parole_booking_dates` (
  `id` BIGINT(20) AUTO_INCREMENT,
  `inmate_id` BIGINT(20) NULL DEFAULT NULL,
  `date` DATE NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Umar',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_parole_booking_dates_inmates1_idx` (`inmate_id` ASC),
  UNIQUE INDEX `md5_hash_UNIQUE` (`md5_hash` ASC),
  CONSTRAINT `fk_parole_booking_dates_inmates9`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`ct_new_haven_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

