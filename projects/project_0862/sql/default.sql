CREATE TABLE IF NOT EXISTS `crime_inmate`.`new_york_inmates` (
  `id` 						BIGINT(20) NOT NULL AUTO_INCREMENT,
  `full_name` 				VARCHAR(255) NULL DEFAULT NULL,
  `first_name` 				VARCHAR(255) NULL DEFAULT NULL,
  `middle_name` 			VARCHAR(255) NULL DEFAULT NULL,
  `last_name` 				VARCHAR(255) NULL DEFAULT NULL,
  `suffix` 					VARCHAR(255) NULL DEFAULT NULL,
  `birthdate` 				YEAR NULL DEFAULT NULL,
  `sex` 					VARCHAR(255) NULL DEFAULT NULL,
  `race` 					VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` 		TEXT NULL DEFAULT NULL,
  `created_by` 				VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 				DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 				DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 					BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 			BIGINT(20) NULL DEFAULT NULL,
  `deleted` 				TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 				VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #862';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`new_york_inmate_additional_info` (
  `id` 					BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` 			BIGINT(20) NULL DEFAULT NULL,
  `key` 				VARCHAR(255) NULL DEFAULT NULL,
  `value` 				VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` 	TEXT NULL DEFAULT NULL,
  `created_by` 			VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 			DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 				BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id`	 	BIGINT(20) NULL DEFAULT NULL,
  `deleted` 			TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 			VARCHAR(255) NULL DEFAULT NULL,
  INDEX `fk_new_york_inmate_additional_info1_idx` (`inmate_id` ASC),
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_new_york_inmate_additional_info1`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`new_york_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #862';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`new_york_inmate_ids` (
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
  `touched_run_id`	BIGINT(20) NULL DEFAULT NULL,
  `deleted` 		TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 		VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_new_york_inmate_ids1_idx` (`inmate_id` ASC),
  CONSTRAINT `fk_new_york_inmate_ids_new_york_inmates1`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`new_york_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #862';


CREATE TABLE IF NOT EXISTS `crime_inmate`.`new_york_arrests` (
  `id` 						BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` 				BIGINT(20) NULL DEFAULT NULL,
  `arrest_date` 			DATETIME NULL DEFAULT NULL,
  `booking_date` 			DATETIME NULL DEFAULT NULL,
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
  INDEX `fk_new_york_arrests_idx` (`inmate_id` ASC) ,
  CONSTRAINT `fk_new_york_arrests__arrestees`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`new_york_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #862';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`new_york_arrests_additional` (
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
  INDEX `fk_new_york_arrests_additional_1_idx` (`arrest_id` ASC) ,
  CONSTRAINT `fk_new_york_arrests_additional_1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`new_york_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #862';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`new_york_charges` (
  `id` 				BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` 		BIGINT(20) NULL DEFAULT NULL,
  `docket_number` 	VARCHAR(255) NULL DEFAULT NULL,
  `offense_type` 	VARCHAR(255) NULL DEFAULT NULL,
  `crime_class` 	VARCHAR(255) NULL DEFAULT NULL,
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
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_new_york_charges_new_york_arrests1_idx` (`arrest_id` ASC),
  CONSTRAINT `fk_new_york_charges_new_york_arrests1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`new_york_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #862';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`new_york_charges_additional` (
  `id` 				BIGINT(20) NOT NULL AUTO_INCREMENT,
  `charge_id` 		BIGINT(20) NULL DEFAULT NULL,
  `key` 			VARCHAR(255) NULL DEFAULT NULL,
  `value` 			VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` 		VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 		DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 			BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 	BIGINT(20) NULL DEFAULT NULL,
  `deleted` 		TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 		VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_new_york_charges_additional_charges1_idx` (`charge_id` ASC),
  CONSTRAINT `fk_new_york_charges_additional_charges1`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`new_york_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #862';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`new_york_bonds` (
  `id` 				BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` 		BIGINT(20) NULL DEFAULT NULL,
  `charge_id` 		BIGINT(20) NULL DEFAULT NULL,
  `bond_type` 		VARCHAR(255) NULL DEFAULT NULL,
  `bond_amount` 	VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` 		VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at`		DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 			BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 	BIGINT(20) NULL DEFAULT NULL,
  `deleted` 		TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 		VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_new_york_bonds_new_york_arrests1_idx` (`arrest_id` ASC),
  INDEX `fk_new_york_bonds_new_york_charges1_idx` (`charge_id` ASC),
  CONSTRAINT `fk_new_york_bonds_inew_york_arrests1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`new_york_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_new_york_bonds_new_york_charges1`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`new_york_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #862';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`new_york_court_hearings` (
  `id` 					BIGINT(20) NOT NULL AUTO_INCREMENT,
  `charge_id` 			BIGINT(20) NULL DEFAULT NULL,
  `court_name` 			VARCHAR(255) NULL DEFAULT NULL,
  `court_date` 			DATE NULL DEFAULT NULL,
  `next_court_date` 	DATE NULL DEFAULT NULL,
  `court_room` 			VARCHAR(255) NULL DEFAULT NULL,
  `case_number` 		VARCHAR(255) NULL DEFAULT NULL,
  `case_type` 			VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` 	TEXT NULL DEFAULT NULL,
  `created_by` 			VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 			DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 				BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 		BIGINT(20) NULL DEFAULT NULL,
  `deleted` 			TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 			VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_new_york_court_hearings_new_york_charges1_idx` (`charge_id` ASC),
  CONSTRAINT `fk_new_york_court_hearings_new_york_charges1`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`new_york_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #862';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`new_york_holding_facilities` (
  `id` 					BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` 			BIGINT(20) NULL DEFAULT NULL,
  `start_date` 			DATE NULL DEFAULT NULL,
  `actual_release_date` DATE NULL DEFAULT NULL,
  `data_source_url` 	TEXT NULL DEFAULT NULL,
  `created_by` 			VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 			DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 				BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 		BIGINT(20) NULL DEFAULT NULL,
  `deleted` 			TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 			VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_new_york__holding_facilities_new_york__arrests1_idx` (`arrest_id` ASC),
  CONSTRAINT `fk_new_york__holding_facilities_new_york__arrests1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`new_york_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #862';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`new_york_holding_facilities_additional` (
  `id` 					BIGINT(20) NOT NULL AUTO_INCREMENT,
  `holding_facility_id` BIGINT(20) NULL DEFAULT NULL,
  `key` 				VARCHAR(255) NULL DEFAULT NULL,
  `value` 				VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` 	TEXT NULL DEFAULT NULL,
  `created_by` 			VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 			DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 				BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 		BIGINT(20) NULL DEFAULT NULL,
  `deleted` 			TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 			VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_new_york_holding_additional_new_york_facilities2_idx` (`holding_facility_id` ASC),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  CONSTRAINT `fk_new_york_facilities_additional_new_york_facilities2`
    FOREIGN KEY (`holding_facility_id`)
    REFERENCES `crime_inmate`.`new_york_holding_facilities` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #862';


CREATE TABLE IF NOT EXISTS `crime_inmate`.`new_york_inmates_runs`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `status`          VARCHAR(255)       DEFAULT 'processing',
  `created_by`      VARCHAR(255)       DEFAULT 'Anton Tkachuk',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
	COMMENT = 'Created by Anton Tkachuk, Task #862';
  