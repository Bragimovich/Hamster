CREATE TABLE IF NOT EXISTS `crime_inmate`.`nm_bernalillo_disciplinary_reports` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` BIGINT(20) NULL DEFAULT NULL,
  `location` VARCHAR(255) NULL DEFAULT NULL,
  `arrest_date` DATE NULL DEFAULT NULL,
  `type_of_report` VARCHAR(255) NULL DEFAULT NULL,
  `crime_class` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Usman',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `fk_ disciplinary_reports_immates1_idx` (`inmate_id` ASC),
  CONSTRAINT `fk_ disciplinary_reports_immates81`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`nm_bernalillo_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;
