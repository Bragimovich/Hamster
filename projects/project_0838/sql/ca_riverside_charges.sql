CREATE TABLE IF NOT EXISTS `crime_inmate`.`ca_riverside_charges` (
  `id`                BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id`         BIGINT(20) NULL DEFAULT NULL,
  `disposition`       VARCHAR(255) NULL DEFAULT NULL,
  `description`       VARCHAR(255) NULL DEFAULT NULL,
  `offense_type`      VARCHAR(255) NULL DEFAULT NULL,
  `crime_class`       VARCHAR(255) NULL,
  `data_source_url`   TEXT NULL DEFAULT NULL,
  `created_by`        VARCHAR(255) NULL DEFAULT 'Abdul Wahab',
  `created_at`        DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`            BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id`    BIGINT(20) NULL DEFAULT NULL,
  `deleted`           TINYINT(1) NULL DEFAULT '0',
  `md5_hash`          VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC) ,
  INDEX `run_id` (`run_id` ASC) ,
  INDEX `touched_run_id` (`touched_run_id` ASC) ,
  INDEX `deleted` (`deleted` ASC) ,
  INDEX `fk_riverside_tazewell__charges_il_tazewell__arrests1_idx` (`arrest_id` ASC) ,
  CONSTRAINT `fk_riverside_tazewell__charges_il_tazewell__arrests1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`ca_riverside_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci;