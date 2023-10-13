CREATE TABLE IF NOT EXISTS `crime_inmate`.`ok_oklahoma_inmates` (
  `id` 				BIGINT(20) NOT NULL AUTO_INCREMENT,
  `full_name` 		VARCHAR(255) NULL DEFAULT NULL,
  `first_name` 		VARCHAR(255) NULL DEFAULT NULL,
  `middle_name` 	VARCHAR(255) NULL DEFAULT NULL,
  `last_name` 		VARCHAR(255) NULL DEFAULT NULL,
  `suffix` 			VARCHAR(255) NULL DEFAULT NULL,
  `birthdate` 		DATE NULL DEFAULT NULL,
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
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #840';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`ok_oklahoma_inmate_additional_info` (
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
  INDEX `fk_immate_additional_info_immates311_idx` (`inmate_id` ASC),
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_immate_additional_info_immates131`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`ok_oklahoma_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #840';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`ok_oklahoma_arrests` (
  `id` 							BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` 					BIGINT(20) NULL DEFAULT NULL,
  `status` 						VARCHAR(255) NULL DEFAULT NULL,
  `officer` 					VARCHAR(255) NULL,
  `arrest_date` 				DATETIME NULL DEFAULT NULL,
  `booking_date` 				DATETIME NULL DEFAULT NULL,
  `booking_agency` 				VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` 			TEXT NULL DEFAULT NULL,
  `created_by` 					VARCHAR(255) NULL DEFAULT 'Anton Tkachuk',
  `created_at` 					DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` 					DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` 						BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` 				BIGINT(20) NULL DEFAULT NULL,
  `deleted` 					TINYINT(1) NULL DEFAULT '0',
  `md5_hash` 					VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_ok_oklahoma_inmates_ok_oklahoma_arrests_idx` (`inmate_id` ASC),
  CONSTRAINT `fk_ok_oklahoma_inmates_ok_oklahoma__arrests`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`ok_oklahoma_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #840';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`ok_oklahoma_charges` (
  `id` 				BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` 		BIGINT(20) NULL DEFAULT NULL,
  `number` 			VARCHAR(255) NULL DEFAULT NULL,
  `description` 	VARCHAR(255) NULL DEFAULT NULL,
  `offense_type` 	VARCHAR(255) NULL,
  `offense_date` 	DATE NULL DEFAULT NULL,
  `offense_time` 	TIME NULL DEFAULT NULL,
  `counts` 			VARCHAR(255) NULL DEFAULT NULL,
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
  INDEX `fk_ok_oklahoma_charges_ok_oklahoma_arrests1_idx` (`arrest_id` ASC),
  CONSTRAINT `fk_ok_oklahoma_charges_ok_oklahoma_arrests1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`ok_oklahoma_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #840';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`ok_oklahoma_bonds` (
  `id` 					BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` 			BIGINT(20) NULL DEFAULT NULL,
  `charge_id` 			BIGINT(20) NULL DEFAULT NULL,
  `bond_category` 		VARCHAR(255) NULL DEFAULT NULL,
  `bond_number` 		VARCHAR(255) NULL DEFAULT NULL,
  `bond_type` 			VARCHAR(255) NULL DEFAULT NULL,
  `bond_amount` 		VARCHAR(255) NULL DEFAULT NULL,
  `made_bond_release_date` DATE NULL DEFAULT NULL,
  `made_bond_release_time` TIME NULL DEFAULT NULL,
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
  INDEX `fk_ok_oklahoma_bonds_ok_oklahoma_arrests1_idx` (`arrest_id` ASC),
  INDEX `fk_ok_oklahoma_bonds_ok_oklahoma_charges1_idx` (`charge_id` ASC),
  CONSTRAINT `fk_il_ok_oklahoma_bonds_ok_oklahoma_arrests1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`ok_oklahoma_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_ok_oklahoma_bonds_ok_oklahoma_charges1`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`ok_oklahoma_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #840';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`ok_oklahoma_court_hearings` (
  `id` 					BIGINT(20) NOT NULL AUTO_INCREMENT,
  `charge_id` 			BIGINT(20) NULL DEFAULT NULL,
  `court_name` 			VARCHAR(255) NULL DEFAULT NULL,
  `court_date` 			DATE NULL DEFAULT NULL,
  `court_time` 			TIME NULL DEFAULT NULL,
  `case_number` 		VARCHAR(255) NULL DEFAULT NULL,
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
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_ok_oklahoma_court_hearings_ok_oklahoma_charges1_idx` (`charge_id` ASC),
  CONSTRAINT `fk_ok_oklahoma_court_hearings_ok_oklahoma_charges1`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`ok_oklahoma_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #840';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`ok_oklahoma_mugshots` (
  `id` 					BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` 			BIGINT(20) NULL DEFAULT NULL,
  `aws_link` 			VARCHAR(255) NULL DEFAULT NULL,
  `original_link` 		mediumtext NULL DEFAULT NULL,
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
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_ok_oklahoma_mugshots_ok_oklahoma_inmates1_idx` (`inmate_id` ASC),
  CONSTRAINT `fk_ok_oklahoma_mugshots_ok_oklahoma_inmates`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`ok_oklahoma_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Anton Tkachuk, Task #840';

CREATE TABLE IF NOT EXISTS `crime_inmate`.`ok_oklahoma_inmates_runs`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `status`          VARCHAR(255)       DEFAULT 'processing',
  `created_by`      VARCHAR(255)       DEFAULT 'Anton Tkachuk',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
	COMMENT = 'Created by Anton Tkachuk, Task #840';
  