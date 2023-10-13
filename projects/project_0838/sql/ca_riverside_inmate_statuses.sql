CREATE TABLE IF NOT EXISTS `crime_inmate`.`ca_riverside_inmate_statuses` (
  `id`                    BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id`             BIGINT(20) NULL DEFAULT NULL,
  `status`                VARCHAR(255) NULL DEFAULT NULL,
  `date_of_status_change` DATE NULL DEFAULT NULL,
  `notes`                 VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url`       TEXT NULL DEFAULT NULL,
  `created_by`            VARCHAR(255) NULL DEFAULT 'Abdul Wahab',
  `created_at`            DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id`        BIGINT(20) NULL DEFAULT NULL,
  `deleted`               TINYINT(1) NULL DEFAULT '0',
  `md5_hash`              VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_riverside_immate_statuses_immates1_idx` (`inmate_id` ASC) ,
  UNIQUE INDEX `md5_hash_UNIQUE` (`md5_hash` ASC) ,
  CONSTRAINT `fk_riverside_immate_statuses_immates1`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`ca_riverside_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci;
