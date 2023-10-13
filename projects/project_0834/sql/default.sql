CREATE TABLE IF NOT EXISTS `crime_inmate`.`tx_bexar_inmates` (
  `id` 				BIGINT(20) NOT NULL AUTO_INCREMENT,
  `full_name` 		VARCHAR(255) NULL DEFAULT NULL,
  `first_name` 		VARCHAR(255) NULL DEFAULT NULL,
  `middle_name` 	VARCHAR(255) NULL DEFAULT NULL,
  `last_name` 		VARCHAR(255) NULL DEFAULT NULL,
  `suffix` 			VARCHAR(255) NULL DEFAULT NULL,
  `birthdate` 		DATE NULL DEFAULT NULL,
  `age` 			BIGINT(20) NULL DEFAULT NULL,
  `date_of_death` 	DATE NULL DEFAULT NULL,
  `sex` 			VARCHAR(5) NULL DEFAULT NULL,
  `race` 			VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` 		VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 		DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 			BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 	BIGINT(20) NULL DEFAULT NULL,
  `deleted` 		TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 		VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC) ,
  INDEX `touched_run_id` (`touched_run_id` ASC) ,
  INDEX `deleted` (`deleted` ASC))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #834';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`tx_bexar_inmate_ids` (
  `id` 				BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` 		BIGINT(20) NULL DEFAULT NULL,
  `number` 			VARCHAR(255) NULL DEFAULT NULL,
  `type` 			VARCHAR(255) NULL DEFAULT NULL,
  `date_from` 		DATE NULL DEFAULT NULL,
  `date_to` 		DATE NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` 		VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
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
  INDEX `fk_tx_bexar_inmate_ids_idx` (`inmate_id` ASC) ,
  CONSTRAINT `fk_tx_bexar_inmate_ids__arrestees1`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`tx_bexar_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #834';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`tx_bexar_arrests` (
  `id` 						BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` 				BIGINT(20) NULL DEFAULT NULL,
  `status` 					VARCHAR(255) NULL DEFAULT NULL,
  `officer` 				VARCHAR(255) NULL,
  `arrest_date` 			DATETIME NULL DEFAULT NULL,
  `booking_date` 			DATETIME NULL DEFAULT NULL,
  `booking_agency` 			VARCHAR(255) NULL DEFAULT NULL,
  `booking_agency_type` 	VARCHAR(255) NULL DEFAULT NULL,
  `booking_agency_subtype` 	VARCHAR(255) NULL DEFAULT NULL,
  `booking_number` 			VARCHAR(255) NULL DEFAULT NULL,
  `actual_booking_number` 	VARCHAR(255) NULL,
  `data_source_url` 		TEXT NULL DEFAULT NULL,
  `created_by` 				VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 				DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 				DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 					BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 			BIGINT(20) NULL DEFAULT NULL,
  `deleted` 				TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 				VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC) ,
  INDEX `run_id` (`run_id` ASC) ,
  INDEX `touched_run_id` (`touched_run_id` ASC) ,
  INDEX `deleted` (`deleted` ASC) ,
  INDEX `fk_tx_bexar_arrests_idx` (`inmate_id` ASC) ,
  CONSTRAINT `fk_tx_bexar_arrests__arrestees`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`tx_bexar_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #834';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`tx_bexar_charges` (
  `id` 					BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` 			BIGINT(20) NULL DEFAULT NULL,
  `number` 				VARCHAR(255) NULL DEFAULT NULL,
  `disposition` 		VARCHAR(255) NULL DEFAULT NULL,
  `disposition_date` 	DATE NULL DEFAULT NULL,
  `description` 		VARCHAR(255) NULL DEFAULT NULL,
  `offense_type` 		VARCHAR(255) NULL,
  `offense_date` 		DATE NULL DEFAULT NULL,
  `offense_time` 		TIME NULL DEFAULT NULL,
  `attempt_or_commit` 	VARCHAR(255) NULL DEFAULT NULL,
  `docket_number` 		VARCHAR(255) NULL DEFAULT NULL,
  `crime_class` 		VARCHAR(255) NULL,
  `acs` 				VARCHAR(255) NULL DEFAULT NULL,
  `counts` 				VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` 	TEXT NULL DEFAULT NULL,
  `created_by` 			VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 			DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 				BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id`		BIGINT(20) NULL DEFAULT NULL,
  `deleted` 			TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 			VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC) ,
  INDEX `run_id` (`run_id` ASC) ,
  INDEX `touched_run_id` (`touched_run_id` ASC) ,
  INDEX `deleted` (`deleted` ASC) ,
  INDEX `fk_tx_bexar_arrests_idx` (`arrest_id` ASC) ,
  CONSTRAINT `fk_tx_bexar_arrests__arrests1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`tx_bexar_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #834';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`tx_bexar_bonds` (
  `id` 						BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` 				BIGINT(20) NULL DEFAULT NULL,
  `charge_id` 				BIGINT(20) NULL DEFAULT NULL,
  `bond_category` 			VARCHAR(255) NULL DEFAULT NULL,
  `bond_number` 			VARCHAR(255) NULL DEFAULT NULL,
  `bond_type` 				VARCHAR(255) NULL DEFAULT NULL,
  `bond_amount` 			VARCHAR(255) NULL DEFAULT NULL,
  `paid` 					INT(11) NULL DEFAULT NULL,
  `bond_fees` 				VARCHAR(45) NULL,
  `paid_status` 			VARCHAR(1020) NULL,
  `made_bond_release_date` 	DATE NULL DEFAULT NULL,
  `made_bond_release_time` 	TIME NULL DEFAULT NULL,
  `data_source_url` 		TEXT NULL DEFAULT NULL,
  `created_by` 				VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 				DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 				DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 					BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 			BIGINT(20) NULL DEFAULT NULL,
  `deleted` 				TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 				VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC) ,
  INDEX `run_id` (`run_id` ASC) ,
  INDEX `touched_run_id` (`touched_run_id` ASC) ,
  INDEX `deleted` (`deleted` ASC) ,
  INDEX `fk_tx_bexar_bonds_idx` (`arrest_id` ASC) ,
  INDEX `fk_tx_bexar_bonds___arrests1_idx` (`charge_id` ASC) ,
  CONSTRAINT `fk_tx_bexar_bonds__bonds1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`tx_bexar_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_tx_bexar_arrests_tx_bexar_arrests1`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`tx_bexar_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #834';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`tx_bexar_arrests_additional` (
  `id` 					BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` 			BIGINT(20) NULL DEFAULT NULL,
  `key` 				VARCHAR(255) NULL DEFAULT NULL,
  `value`				VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` 	TEXT NULL DEFAULT NULL,
  `created_by` 			VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 			DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 				BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 		BIGINT(20) NULL DEFAULT NULL,
  `deleted` 			TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 			VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC) ,
  INDEX `run_id` (`run_id` ASC) ,
  INDEX `touched_run_id` (`touched_run_id` ASC) ,
  INDEX `deleted` (`deleted` ASC) ,
  INDEX `fk_tx_bexar_arrests_additional_1_idx` (`arrest_id` ASC) ,
  CONSTRAINT `fk_tx_bexar_arrests_additional_1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`tx_bexar_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #834';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`tx_bexar_inmates_runs`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `status`          VARCHAR(255)       DEFAULT 'processing',
  `created_by`      VARCHAR(255)       DEFAULT 'Anton Tkachuk',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
	COMMENT = 'Created by Anton Tkachuk, Task #834';
  