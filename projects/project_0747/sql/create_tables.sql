CREATE TABLE IF NOT EXISTS `crime_inmate`.`arkansas_inmates` (
  `id`    			BIGINT(20) NOT NULL AUTO_INCREMENT,
  `full_name` 		VARCHAR(255) NULL DEFAULT NULL,
  `first_name` 		VARCHAR(255) NULL DEFAULT NULL,
  `middle_name` 	VARCHAR(255) NULL DEFAULT NULL,
  `last_name` 		VARCHAR(255) NULL DEFAULT NULL,
  `suffix` 			VARCHAR(255) NULL DEFAULT NULL,
  `birthdate` 		DATE NULL DEFAULT NULL,
  `sex` 			VARCHAR(255) NULL DEFAULT NULL,
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
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC) )
ENGINE = InnoDB
AUTO_INCREMENT = 0
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #747';


CREATE TABLE IF NOT EXISTS `crime_inmate`.`arkansas_arrests` (
  `id` 					BIGINT(20) NOT NULL AUTO_INCREMENT,
  `immate_id` 			BIGINT(20) NULL DEFAULT NULL,
  `booking_date` 		DATE NULL DEFAULT NULL,
  `booking_agency` 		VARCHAR(255) NULL DEFAULT NULL,
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
  INDEX `fk_il_tazewell__arrests_il_tazewell__arrestees_idx` (`immate_id` ASC) ,
  CONSTRAINT `fk_il_tazewell__arrests_il_tazewell__arrestees1`
    FOREIGN KEY (`immate_id`)
    REFERENCES `crime_inmate`.`arkansas_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
AUTO_INCREMENT = 0
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #747';


CREATE TABLE IF NOT EXISTS `crime_inmate`.`arkansas_holding_facilities_addresses` (
  `id` 					BIGINT(20) NOT NULL AUTO_INCREMENT,
  `full_address` 		VARCHAR(255) NULL DEFAULT NULL,
  `street_address` 		VARCHAR(255) NULL DEFAULT NULL,
  `city` 				VARCHAR(255) NULL DEFAULT NULL,
  `county` 				VARCHAR(255) NULL DEFAULT NULL,
  `state` 				VARCHAR(255) NULL DEFAULT NULL,
  `zip` 				VARCHAR(255) NULL DEFAULT NULL,
  `lan` 				VARCHAR(255) NULL DEFAULT NULL,
  `lon` 				VARCHAR(255) NULL DEFAULT NULL,
   `data_source_url` 	TEXT NULL DEFAULT NULL,
  `created_by` 			VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at`			DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 				BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 		BIGINT(20) NULL DEFAULT NULL,
  `deleted` 			TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 			VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC) ,
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC) )
ENGINE = InnoDB
AUTO_INCREMENT = 0
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #747';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`arkansas_holding_facilities` (
  `id` 					BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` 			BIGINT(20) NULL DEFAULT NULL,
  `holding_facilities_addresse_id` BIGINT(20) NULL,
  `facility` 			VARCHAR(255) NULL DEFAULT NULL,
  `facility_subtype` 	VARCHAR(255) NULL DEFAULT NULL,
  `start_date` 			DATE NULL DEFAULT NULL,
  `planned_release_date` DATE NULL DEFAULT NULL,
  `total_time` 			VARCHAR(255) NULL,
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
  INDEX `fk_il_tazewell__holding_facilities_il_tazewell__arrests1_idx` (`arrest_id` ASC) ,
  INDEX `fk_holding_facilities_holding_facilities_addresses10_idx` (`holding_facilities_addresse_id` ASC) ,
  CONSTRAINT `fk_il_tazewell__holding_facilities_il_tazewell__arrests11`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`arkansas_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_holding_facilities_holding_facilities_addresses10`
    FOREIGN KEY (`holding_facilities_addresse_id`)
    REFERENCES `crime_inmate`.`arkansas_holding_facilities_addresses` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #747';


CREATE TABLE IF NOT EXISTS `crime_inmate`.`arkansas_inmate_ids` (
  `id` 				BIGINT(20) NOT NULL AUTO_INCREMENT,
  `immate_id` 		BIGINT(20) NULL DEFAULT NULL,
  `number` 			VARCHAR(255) NULL DEFAULT NULL,
  `type` 			VARCHAR(255) NULL DEFAULT NULL,
  `date_from` 		DATE NULL DEFAULT NULL,
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
  INDEX `fk_il_tazewell__arrestee_ids_il_tazewell__arrestees1_idx` (`immate_id` ASC) ,
  CONSTRAINT `fk_il_tazewell__arrestee_ids_il_tazewell__arrestees112`
    FOREIGN KEY (`immate_id`)
    REFERENCES `crime_inmate`.`arkansas_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
AUTO_INCREMENT = 0
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #747';


CREATE TABLE IF NOT EXISTS `crime_inmate`.`arkansas_inmate_ids_additional` (
  `id` 				BIGINT(20) NOT NULL AUTO_INCREMENT,
  `key` 			VARCHAR(255) NULL DEFAULT NULL,
  `value` 			VARCHAR(500) NULL DEFAULT NULL,
  `created_by` 		VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 		DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 			BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 	BIGINT(20) NULL DEFAULT NULL,
  `deleted` 		TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 		VARCHAR(255) NULL DEFAULT NULL,
  `arkansas_inmate_ids_id` BIGINT(20) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_arkansas_inmate_ids_additional_arkansas_inmate_ids1_idx` (`arkansas_inmate_ids_id` ASC),
  CONSTRAINT `fk_arkansas_inmate_ids_additional_arkansas_inmate_ids1`
    FOREIGN KEY (`arkansas_inmate_ids_id`)
    REFERENCES `crime_inmate`.`arkansas_inmate_ids` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
AUTO_INCREMENT = 0
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #747';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`arkansas_inmate_aliases` (
  `id` 				BIGINT(20) NOT NULL AUTO_INCREMENT,
  `immate_id` 		BIGINT(20) NULL DEFAULT NULL,
  `full_name` 		VARCHAR(255) NULL DEFAULT NULL,
  `first_name` 		VARCHAR(255) NULL DEFAULT NULL,
  `middle_name` 	VARCHAR(255) NULL DEFAULT NULL,
  `last_name` 		VARCHAR(255) NULL DEFAULT NULL,
  `suffix` 			VARCHAR(255) NULL DEFAULT NULL,
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
  INDEX `fk_il_tazewell__arrestee_aliases_il_tazewell__arrestees10_idx` (`immate_id` ASC) ,
  CONSTRAINT `fk_il_tazewell__arrestee_aliases_il_tazewell__arrestees10`
    FOREIGN KEY (`immate_id`)
    REFERENCES `crime_inmate`.`arkansas_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #747';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`arkansas_mugshots` (
  `id` 					BIGINT(20) NOT NULL AUTO_INCREMENT,
  `immate_id` 			BIGINT(20) NULL DEFAULT NULL,
  `aws_link` 			VARCHAR(255) NULL DEFAULT NULL,
  `original_link` 		VARCHAR(255) NULL DEFAULT NULL,
  `notes` 				VARCHAR(255) NULL DEFAULT NULL,
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
  CONSTRAINT `fk_il_tazewell__mugshots_il_tazewell__arrestees15`
    FOREIGN KEY (`id`)
    REFERENCES `crime_inmate`.`arkansas_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #747';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`arkansas_inmate_additional_info` (
  `id` 					BIGINT(20) NOT NULL AUTO_INCREMENT,
  `immate_id` 			BIGINT(20) NULL DEFAULT NULL,
  `key` 				VARCHAR(255) NULL DEFAULT NULL,
  `value` 				TEXT NULL DEFAULT NULL,
  `created_by` 			VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 			DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 				BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 		BIGINT(20) NULL DEFAULT NULL,
  `deleted` 			TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 			VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_immate_additional_info_immates11_idx` (`immate_id` ASC),
  CONSTRAINT `fk_immate_additional_info_immates11`
    FOREIGN KEY (`immate_id`)
    REFERENCES `crime_inmate`.`arkansas_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
AUTO_INCREMENT = 0
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #747';


CREATE TABLE IF NOT EXISTS `crime_inmate`.`arkansas_charges` (
  `id` 				BIGINT(20) NOT NULL AUTO_INCREMENT,
  `immate_id` 		BIGINT(20) NULL DEFAULT NULL,
  `number` 			VARCHAR(255) NULL DEFAULT NULL,
  `disposition` 	VARCHAR(255) NULL DEFAULT NULL,
  `description` 	VARCHAR(255) NULL DEFAULT NULL,
  `crime_class` 	VARCHAR(255) NULL,
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
  CONSTRAINT `fk_il_tazewell__charges_il_tazewell__arrests11`
    FOREIGN KEY (`immate_id`)
    REFERENCES `crime_inmate`.`arkansas_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #747';


CREATE TABLE IF NOT EXISTS `crime_inmate`.`arkansas_court_hearings` (
  `id` 					BIGINT(20) NOT NULL AUTO_INCREMENT,
  `charge_id` 			BIGINT(20) NULL DEFAULT NULL,
  `court_address_id` 	BIGINT(20) NULL,
  `court_date` 			DATE NULL DEFAULT NULL,
  `court_time` 			TIME NULL DEFAULT NULL,
  `case_number` 		VARCHAR(255) NULL DEFAULT NULL,
  `sentence_lenght` 	VARCHAR(255) NULL,
  `sentence_type` 		VARCHAR(255) NULL,
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
  INDEX `fk_il_tazewell__court_hearings_il_tazewell__charges1_idx` (`charge_id` ASC) ,
  CONSTRAINT `fk_il_tazewell__court_hearings_il_tazewell__charges11`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`arkansas_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #747';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`arkansas_court_hearings_additional` (
  `id` 				BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arkansas_court_hearings_id` BIGINT(20) NOT NULL,
  `key` 			VARCHAR(255) NULL DEFAULT NULL,
  `value` 			VARCHAR(255) NULL DEFAULT NULL,
  `created_by` 		VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 		DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 		DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 			BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 	BIGINT(20) NULL DEFAULT NULL,
  `deleted` 		TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 		VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_arkansas_inmate_additional_info_copy1_arkansas_court_hea_idx` (`arkansas_court_hearings_id` ASC) ,
  CONSTRAINT `fk_arkansas_inmate_additional_info_copy1_arkansas_court_heari1`
    FOREIGN KEY (`arkansas_court_hearings_id`)
    REFERENCES `crime_inmate`.`arkansas_court_hearings` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #747';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`arkansas_charges_additional` (
  `id` 			BIGINT(20) NOT NULL AUTO_INCREMENT,
  `key` 		VARCHAR(255) NULL DEFAULT NULL,
  `value` 		VARCHAR(255) NULL DEFAULT NULL,
  `created_by` 	VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 	DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 	DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 		BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` 	TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 	VARCHAR(255) NULL DEFAULT NULL,
  `arkansas_charges_id` BIGINT(20) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_arkansas_charges_additional_arkansas_charges1_idx` (`arkansas_charges_id` ASC) ,
  CONSTRAINT `fk_arkansas_charges_additional_arkansas_charges1`
    FOREIGN KEY (`arkansas_charges_id`)
    REFERENCES `crime_inmate`.`arkansas_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #747';
