CREATE TABLE IF NOT EXISTS `crime_inmate`.`il_dupage_charges` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` BIGINT(20) NULL DEFAULT NULL,
  `number` VARCHAR(255) NULL DEFAULT NULL,
  `disposition` VARCHAR(255) NULL DEFAULT NULL,
  `disposition_date` DATE NULL DEFAULT NULL,
  `description` VARCHAR(255) NULL DEFAULT NULL,
  `offense_type` VARCHAR(255) NULL,
  `offense_date` DATE NULL DEFAULT NULL,
  `offense_time` TIME NULL DEFAULT NULL,
  `attempt_or_commit` VARCHAR(255) NULL DEFAULT NULL,
  `docket_number` VARCHAR(255) NULL DEFAULT NULL,
  `crime_class` VARCHAR(255) NULL,
  `acs` VARCHAR(255) NULL DEFAULT NULL,
  `counts` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Azeem Arif',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR (255)GENERATED ALWAYS AS (md5(concat_ws('',number,disposition,CAST(disposition_date AS CHAR),description,offense_type,CAST(offense_date AS CHAR),CAST(offense_time AS CHAR),attempt_or_commit,docket_number,crime_class,acs,counts,arrest_id))) STORED,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_il_tazewell__charges_il_tazewell__arrests1_idx` (`arrest_id` ASC),
  CONSTRAINT `fk_il_tazewell__charges_il_tazewell__arrests809`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`il_dupage_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
AUTO_INCREMENT = 2109
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Azeem Arif, Task #809';
