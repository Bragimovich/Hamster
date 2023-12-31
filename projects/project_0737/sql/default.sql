-- MySQL Script generated by MySQL Workbench
-- Mon Apr 10 13:02:05 2023
-- Model: New Model    Version: 1.0
-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema crime_inmate
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema crime_inmate
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `crime_inmate` DEFAULT CHARACTER SET utf8 ;

USE `crime_inmate` ;

-- -----------------------------------------------------
-- Table `crime_inmate`.`inmates`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `crime_inmate`.`in_marion_inmates` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `full_name` VARCHAR(255) NULL DEFAULT NULL,
  `first_name` VARCHAR(255) NULL DEFAULT NULL,
  `middle_name` VARCHAR(255) NULL DEFAULT NULL,
  `last_name` VARCHAR(255) NULL DEFAULT NULL,
  `suffix` VARCHAR(255) NULL DEFAULT NULL,
  `birthdate` DATE NULL DEFAULT NULL,
  `date_of_death` DATE NULL DEFAULT NULL,
  `sex` VARCHAR(5) NULL DEFAULT NULL,
  `race` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Jaffar Hussain',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC)  ,
  INDEX `run_id` (`run_id` ASC)  ,
  INDEX `touched_run_id` (`touched_run_id` ASC)  ,
  INDEX `deleted` (`deleted` ASC)  )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Jaffar Hussain, Task #737';



-- -----------------------------------------------------
-- Table `crime_inmate`.`inmate_ids`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `crime_inmate`.`in_marion_inmate_ids` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `immate_id` BIGINT(20) NULL DEFAULT NULL,
  `number` VARCHAR(255) NULL DEFAULT NULL,
  `type` VARCHAR(255) NULL DEFAULT NULL,
  `date_from` DATE NULL DEFAULT NULL,
  `date_to` DATE NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Jaffar Hussain',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC)  ,
  INDEX `run_id` (`run_id` ASC)  ,
  INDEX `touched_run_id` (`touched_run_id` ASC)  ,
  INDEX `deleted` (`deleted` ASC)  ,
  INDEX `fk_il_tazewell__arrestee_ids_il_tazewell__arrestees1_idx` (`immate_id` ASC)  ,
  CONSTRAINT `fk_il_tazewell__arrestee_ids_il_tazewell__arrestees1`
    FOREIGN KEY (`immate_id`)
    REFERENCES `crime_inmate`.`in_marion_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Jaffar Hussain, Task #737';



-- -----------------------------------------------------
-- Table `crime_inmate`.`arrests`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `crime_inmate`.`in_marion_arrests` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `immate_id` BIGINT(20) NULL DEFAULT NULL,
  `status` VARCHAR(255) NULL DEFAULT NULL,
  `officer` VARCHAR(255) NULL,
  `arrest_date` DATE NULL DEFAULT NULL,
  `booking_date` DATE NULL DEFAULT NULL,
  `booking_agency` VARCHAR(255) NULL DEFAULT NULL,
  `booking_agency_type` VARCHAR(255) NULL DEFAULT NULL,
  `booking_agency_subtype` VARCHAR(255) NULL DEFAULT NULL,
  `booking_number` VARCHAR(255) NULL DEFAULT NULL,
  `actual_booking_number` VARCHAR(255) NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Jaffar Hussain',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC)  ,
  INDEX `run_id` (`run_id` ASC)  ,
  INDEX `touched_run_id` (`touched_run_id` ASC)  ,
  INDEX `deleted` (`deleted` ASC)  ,
  INDEX `fk_il_tazewell__arrests_il_tazewell__arrestees_idx` (`immate_id` ASC)  ,
  CONSTRAINT `fk_il_tazewell__arrests_il_tazewell__arrestees`
    FOREIGN KEY (`immate_id`)
    REFERENCES `crime_inmate`.`in_marion_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Jaffar Hussain, Task #737';



-- -----------------------------------------------------
-- Table `crime_inmate`.`charges`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `crime_inmate`.`in_marion_charges` (
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
  `docker_number` VARCHAR(255) NULL DEFAULT NULL,
  `crime_class` VARCHAR(255) NULL,
  `acs` VARCHAR(255) NULL DEFAULT NULL,
  `counts` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Jaffar Hussain',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC)  ,
  INDEX `run_id` (`run_id` ASC)  ,
  INDEX `touched_run_id` (`touched_run_id` ASC)  ,
  INDEX `deleted` (`deleted` ASC)  ,
  INDEX `fk_il_tazewell__charges_il_tazewell__arrests1_idx` (`arrest_id` ASC)  ,
  CONSTRAINT `fk_il_tazewell__charges_il_tazewell__arrests1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`in_marion_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Jaffar Hussain, Task #737';



-- -----------------------------------------------------
-- Table `crime_inmate`.`bonds`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `crime_inmate`.`in_marion_bonds` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `arrest_id` BIGINT(20) NULL DEFAULT NULL,
  `charge_id` BIGINT(20) NULL DEFAULT NULL,
  `bond_category` VARCHAR(255) NULL DEFAULT NULL,
  `bond_number` VARCHAR(255) NULL DEFAULT NULL,
  `bond_type` VARCHAR(255) NULL DEFAULT NULL,
  `bond_amount` VARCHAR(255) NULL DEFAULT NULL,
  `paid` INT(11) NULL DEFAULT NULL,
  `bond_fees` VARCHAR(45) NULL,
  `paid_status` VARCHAR(1020) NULL,
  `made_bond_release_date` DATE NULL DEFAULT NULL,
  `made_bond_release_time` TIME NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Jaffar Hussain',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC)  ,
  INDEX `run_id` (`run_id` ASC)  ,
  INDEX `touched_run_id` (`touched_run_id` ASC)  ,
  INDEX `deleted` (`deleted` ASC)  ,
  INDEX `fk_il_tazewell__bonds_il_tazewell__bonds1_idx` (`arrest_id` ASC)  ,
  INDEX `fk_il_tazewell__bonds_il_tazewell__arrests1_idx` (`charge_id` ASC)  ,
  CONSTRAINT `fk_il_tazewell__bonds_il_tazewell__bonds1`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`in_marion_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_il_tazewell__bonds_il_tazewell__arrests1`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`in_marion_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Jaffar Hussain, Task #737';



-- -----------------------------------------------------
-- Table `crime_inmate`.`court_hearings`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `crime_inmate`.`in_marion_court_hearings` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `charge_id` BIGINT(20) NULL DEFAULT NULL,
  `court_address_id` BIGINT(20) NULL,
  `court_name` VARCHAR(255) NULL DEFAULT NULL,
  `court_date` DATE NULL DEFAULT NULL,
  `court_time` TIME NULL DEFAULT NULL,
  `next_court_date` DATE NULL,
  `next_court_time` TIME NULL,
  `court_room` VARCHAR(255) NULL DEFAULT NULL,
  `case_number` VARCHAR(255) NULL DEFAULT NULL,
  `case_type` VARCHAR(255) NULL DEFAULT NULL,
  `sentence_lenght` VARCHAR(255) NULL,
  `sentence_type` VARCHAR(255) NULL,
  `min_release_date` DATE NULL,
  `max_release_date` DATE NULL,
  `set_by` BIGINT(20) NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Jaffar Hussain',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC)  ,
  INDEX `run_id` (`run_id` ASC)  ,
  INDEX `touched_run_id` (`touched_run_id` ASC)  ,
  INDEX `deleted` (`deleted` ASC)  ,
  INDEX `fk_il_tazewell__court_hearings_il_tazewell__charges1_idx` (`charge_id` ASC)  ,
  INDEX `fk_court_hearings_court_addresses1_idx` (`court_address_id` ASC)  ,
  CONSTRAINT `fk_il_tazewell__court_hearings_il_tazewell__charges1`
    FOREIGN KEY (`charge_id`)
    REFERENCES `crime_inmate`.`in_marion_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Jaffar Hussain, Task #737';



-- -----------------------------------------------------
-- Table `crime_inmate`.`inmate_additional_info`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `crime_inmate`.`in_marion_inmate_additional_info` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `inmate_id` BIGINT(20) NULL DEFAULT NULL,
  `height` VARCHAR(255) NULL DEFAULT NULL,
  `weight` VARCHAR(255) NULL DEFAULT NULL,
  `hair_color` VARCHAR(255) NULL DEFAULT NULL,
  `eye_color` VARCHAR(255) NULL DEFAULT NULL,
  `street_address` VARCHAR(255) NULL DEFAULT NULL,
  `age` INT(11) NULL DEFAULT NULL,
  `age_as_of_date` INT(11) NULL DEFAULT NULL,
  `complexion` VARCHAR(255) NULL DEFAULT NULL,
  `build` VARCHAR(255) NULL DEFAULT NULL,
  `risk_level` VARCHAR(255) NULL DEFAULT NULL,
  `visitation_status` VARCHAR(255) NULL DEFAULT NULL,
  `body_modification_raw` VARCHAR(255) NULL DEFAULT NULL,
  `scars` VARCHAR(255) NULL DEFAULT NULL,
  `marks` VARCHAR(255) NULL DEFAULT NULL,
  `tattoos` VARCHAR(255) NULL DEFAULT NULL,
  `current_location` VARCHAR(255) NULL DEFAULT NULL,
  `work_or_program_participation` VARCHAR(255) NULL DEFAULT NULL,
  `hair_length` VARCHAR(45) NULL,
  `ethnicity` VARCHAR(45) NULL,
  `marital_status` VARCHAR(45) NULL,
  `citizen` VARCHAR(45) NULL,
  `county_of_birth` VARCHAR(45) NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Jaffar Hussain',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `fk_immate_additional_info_immates1_idx` (`inmate_id` ASC)  ,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC)  ,
  INDEX `run_id` (`run_id` ASC)  ,
  INDEX `touched_run_id` (`touched_run_id` ASC)  ,
  INDEX `deleted` (`deleted` ASC)  ,
  CONSTRAINT `fk_immate_additional_info_immates1`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`in_marion_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB 
COMMENT = 'Created by Jaffar Hussain, Task #737';



-- -----------------------------------------------------
-- Table `crime_inmate`.`inmate_statuses`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `crime_inmate`.`in_marion_inmate_statuses` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `immate_id` BIGINT(20) NULL DEFAULT NULL,
  `status` VARCHAR(255) NULL DEFAULT NULL,
  `date_of_status_change` DATE NULL,
  `notes` VARCHAR(255) NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Jaffar Hussain',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_immate_statuses_immates1_idx` (`immate_id` ASC)  ,
  CONSTRAINT `fk_immate_statuses_immates1`
    FOREIGN KEY (`immate_id`)
    REFERENCES `crime_inmate`.`in_marion_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB 
COMMENT = 'Created by Jaffar Hussain, Task #737';



-- -----------------------------------------------------
-- Table `crime_inmate`.`inmate_ids_additional`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `crime_inmate`.`in_marion_inmate_ids_additional` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `immate_id` BIGINT(20) NULL DEFAULT NULL,
  `state_id` VARCHAR(255) NULL DEFAULT NULL,
  `police_or_county_id` VARCHAR(255) NULL DEFAULT NULL,
  `fbi` VARCHAR(255) NULL DEFAULT NULL,
  `ice` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Jaffar Hussain',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC)  ,
  INDEX `run_id` (`run_id` ASC)  ,
  INDEX `touched_run_id` (`touched_run_id` ASC)  ,
  INDEX `deleted` (`deleted` ASC)  ,
  INDEX `fk_il_tazewell__arrestee_ids_il_tazewell__arrestees1_idx` (`immate_id` ASC)  ,
  CONSTRAINT `fk_il_tazewell__arrestee_ids_il_tazewell__arrestees10`
    FOREIGN KEY (`immate_id`)
    REFERENCES `crime_inmate`.`in_marion_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Jaffar Hussain, Task #737';



-- -----------------------------------------------------
-- Table `crime_inmate`.`bonds_additional`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `crime_inmate`.`in_marion_bonds_additional` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `bonds_id` BIGINT(20) NOT NULL,
  `percent` VARCHAR(255) NULL DEFAULT NULL,
  `posted_by` VARCHAR(255) NULL DEFAULT NULL,
  `additional` VARCHAR(255) NULL DEFAULT NULL,
  `post_date` DATE NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Jaffar Hussain',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC)  ,
  INDEX `run_id` (`run_id` ASC)  ,
  INDEX `touched_run_id` (`touched_run_id` ASC)  ,
  INDEX `deleted` (`deleted` ASC)  ,
  INDEX `fk_bonds_additional_bonds1_idx` (`bonds_id` ASC)  ,
  CONSTRAINT `fk_bonds_additional_bonds1`
    FOREIGN KEY (`bonds_id`)
    REFERENCES `crime_inmate`.`in_marion_bonds` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Jaffar Hussain, Task #737';



-- -----------------------------------------------------
-- Table `crime_inmate`.`charges_additional`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `crime_inmate`.`in_marion_charges_additional` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `offense_degree` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Jaffar Hussain',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  `charges_id` BIGINT(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC)  ,
  INDEX `run_id` (`run_id` ASC)  ,
  INDEX `touched_run_id` (`touched_run_id` ASC)  ,
  INDEX `deleted` (`deleted` ASC)  ,
  INDEX `fk_charges_copy1_charges1_idx` (`charges_id` ASC)  ,
  CONSTRAINT `fk_charges_copy1_charges1`
    FOREIGN KEY (`charges_id`)
    REFERENCES `crime_inmate`.`in_marion_charges` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Jaffar Hussain, Task #737';

-- -----------------------------------------------------
-- Table `crime_inmate`.`in_marion_holding_facilities`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `crime_inmate`.`in_marion_holding_facilities` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `full_address` VARCHAR(255) NULL DEFAULT NULL,
  `facility_type` VARCHAR(255) NULL DEFAULT NULL,
  `start_date` DATE NULL DEFAULT NULL,
  `planned_release_date` DATE NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Jaffar Hussain',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC)  ,
  INDEX `run_id` (`run_id` ASC)  ,
  INDEX `touched_run_id` (`touched_run_id` ASC)  ,
  INDEX `deleted` (`deleted` ASC)  )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Jaffar Hussain, Task #737';

-- -----------------------------------------------------
-- Table `crime_inmate`.`in_marion_inmate_meta`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `crime_inmate`.`in_marion_inmate_meta`(
    `id` INT auto_increment PRIMARY KEY,
    `inmate_id` INT,
    `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
    `created_by` VARCHAR(255) DEFAULT 'Jaffar',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- indexes 
    UNIQUE INDEX `md5` (`md5_hash`),
    INDEX `inmate_id_idx` (`inmate_id`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Jaffar Hussain, Task #737';

-- -----------------------------------------------------
-- Table `crime_inmate`.`in_marion_inmate_aliases`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `crime_inmate`.`in_marion_inmate_aliases` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `full_name` VARCHAR(255) NULL DEFAULT NULL,
  `first_name` VARCHAR(255) NULL DEFAULT NULL,
  `middle_name` VARCHAR(255) NULL DEFAULT NULL,
  `last_name` VARCHAR(255) NULL DEFAULT NULL,
  `data_source_url` TEXT NULL DEFAULT NULL,
  `created_by` VARCHAR(255) NULL DEFAULT 'Jaffar Hussain',
  `created_at` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id` BIGINT(20) NULL DEFAULT NULL,
  `touched_run_id` BIGINT(20) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT '0',
  `md5_hash` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC)  ,
  INDEX `run_id` (`run_id` ASC)  ,
  INDEX `touched_run_id` (`touched_run_id` ASC)  ,
  INDEX `deleted` (`deleted` ASC)  )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Jaffar Hussain, Task #737';


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
