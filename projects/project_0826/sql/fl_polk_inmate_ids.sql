CREATE TABLE IF NOT EXISTS `crime_inmate`.`fl_polk_inmate_ids` (
  `id` 				BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` 		BIGINT(20) NULL DEFAULT NULL,
  `number` 			VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` 		VARCHAR(255) NULL DEFAULT 'Hatri',
  `created_at` 		DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 			BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 	BIGINT(20) NULL DEFAULT NULL,
  `deleted` 		TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 		VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC) ,
  INDEX `run_id` (`run_id` ASC) ,
  INDEX `touched_run_id` (`touched_run_id` ASC) ,
  INDEX `deleted` (`deleted` ASC) ,
  INDEX `fk_fl_polk_inmate_ids_idx` (`inmate_id` ASC) ,
  CONSTRAINT `fk_fl_polk_inmate_ids__arrestees1`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`fl_polk_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Hatri, Task #826';
