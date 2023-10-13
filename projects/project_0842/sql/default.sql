CREATE TABLE `crime_inmate`.`ct_hartfold_inmates` (
  `id`              BIGINT(20)   NOT NULL AUTO_INCREMENT,
  `full_name`       VARCHAR(255),
  `first_name`      VARCHAR(255),
  `middle_name`     VARCHAR(255),
  `last_name`       VARCHAR(255),
  `birthdate`       DATE,
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)          DEFAULT 'Ray Piao',
  `created_at`      DATETIME              DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT(20),
  `deleted`         TINYINT(1)            DEFAULT '0',
  `md5_hash`        VARCHAR(255),
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC)
) DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Ray Piao, Task #842';

CREATE TABLE `crime_inmate`.`ct_hartfold_inmate_ids` (
  `id`              BIGINT(20)   NOT NULL AUTO_INCREMENT,
  `inmate_id`       BIGINT(20),
  `number`          VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)          DEFAULT 'Ray Piao',
  `created_at`      DATETIME              DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT(20),
  `deleted`         TINYINT(1)            DEFAULT '0',
  `md5_hash`        VARCHAR(255),
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_ct_hartfold__inmate_ids_ct_hartfold__inmates_idx` (`inmate_id` ASC),
  CONSTRAINT `fk_ct_hartfold__inmate_ids_ct_hartfold__inmates`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`ct_hartfold_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Ray Piao, Task #842';

CREATE TABLE `crime_inmate`.`ct_hartfold_arrests` (
  `id`              BIGINT(20)   NOT NULL AUTO_INCREMENT,
  `inmate_id`       BIGINT(20),
  `status`          VARCHAR(255),
  `booking_date`    DATETIME,
  `booking_agency`  VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)          DEFAULT 'Ray Piao',
  `created_at`      DATETIME              DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT(20),
  `deleted`         TINYINT(1)            DEFAULT '0',
  `md5_hash`        VARCHAR(255),
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_ct_hartfold__arrests_ct_hartfold__inmates_idx` (`inmate_id` ASC),
  CONSTRAINT `fk_ct_hartfold__arrests_ct_hartfold__inmates`
    FOREIGN KEY (`inmate_id`)
    REFERENCES `crime_inmate`.`ct_hartfold_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Ray Piao, Task #842';

CREATE TABLE `crime_inmate`.`ct_hartfold_bonds` (
  `id`              BIGINT(20)   NOT NULL AUTO_INCREMENT,
  `arrest_id`       BIGINT(20),
  `bond_amount`     VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)          DEFAULT 'Ray Piao',
  `created_at`      DATETIME              DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT(20),
  `deleted`         TINYINT(1)            DEFAULT '0',
  `md5_hash`        VARCHAR(255),
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_ct_hartfold__bonds_ct_hartfold__arrests_idx` (`arrest_id` ASC),
  CONSTRAINT `fk_ct_hartfold__bonds_ct_hartfold__arrests`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`ct_hartfold_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Ray Piao, Task #842';

CREATE TABLE `crime_inmate`.`ct_hartfold_holding_facilities_addresses` (
  `id`             BIGINT(20)   NOT NULL AUTO_INCREMENT,
  `full_address`   VARCHAR(255),
  `street_address` VARCHAR(255),
  `city`           VARCHAR(255),
  `state`          VARCHAR(255),
  `zip`            VARCHAR(255),
  `created_by`     VARCHAR(255)          DEFAULT 'Ray Piao',
  `created_at`     DATETIME              DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`         BIGINT(20),
  `touched_run_id` BIGINT(20),
  `deleted`        TINYINT(1)            DEFAULT '0',
  `md5_hash`       VARCHAR(255),
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC)
) DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Ray Piao, Task #842';

CREATE TABLE `crime_inmate`.`ct_hartfold_holding_facilities` (
  `id`                             BIGINT(20)   NOT NULL AUTO_INCREMENT,
  `arrest_id`                      BIGINT(20),
  `holding_facilities_addresse_id` BIGINT(20),
  `facility`                       VARCHAR(255),
  `planned_release_date`           DATE,
  `max_release_date`               VARCHAR(255),
  `data_source_url`                TEXT,
  `created_by`                     VARCHAR(255)          DEFAULT 'Ray Piao',
  `created_at`                     DATETIME              DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                         BIGINT(20),
  `touched_run_id`                 BIGINT(20),
  `deleted`                        TINYINT(1)            DEFAULT '0',
  `md5_hash`                       VARCHAR(255),
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_ct_hartfold__holding_facilities_ct_hartfold__arrests_idx` (`arrest_id` ASC),
  INDEX `fk__holding_facilities__holding_facilities_addresses_idx` (`holding_facilities_addresse_id` ASC),
  CONSTRAINT `fk_ct_hartfold__holding_facilities_ct_hartfold__arrests`
    FOREIGN KEY (`arrest_id`)
    REFERENCES `crime_inmate`.`ct_hartfold_arrests` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk__holding_facilities__holding_facilities_addresses`
    FOREIGN KEY (`holding_facilities_addresse_id`)
    REFERENCES `crime_inmate`.`ct_hartfold_holding_facilities_addresses` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Ray Piao, Task #842';

CREATE TABLE `crime_inmate`.`ct_hartfold_mugshots` (
  `id`              BIGINT(20)   NOT NULL AUTO_INCREMENT,
  `immate_id`       BIGINT(20),
  `aws_link`        VARCHAR(255),
  `original_link`   VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)          DEFAULT 'Ray Piao',
  `created_at`      DATETIME              DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT(20),
  `deleted`         TINYINT(1)            DEFAULT '0',
  `md5_hash`        VARCHAR(255),
  PRIMARY KEY (`id`),
  UNIQUE INDEX `md5` (`md5_hash` ASC),
  INDEX `run_id` (`run_id` ASC),
  INDEX `touched_run_id` (`touched_run_id` ASC),
  INDEX `deleted` (`deleted` ASC),
  INDEX `fk_ct_hartfold__mugshots_ct_hartfold__inmates_idx` (`immate_id` ASC),
  CONSTRAINT `fk_ct_hartfold__mugshots_ct_hartfold__inmates`
    FOREIGN KEY (`immate_id`)
    REFERENCES `crime_inmate`.`ct_hartfold_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Ray Piao, Task #842';

CREATE TABLE `crime_inmate`.`ct_hartfold_parole_booking_dates` (
  `id`             BIGINT(20)   NOT NULL AUTO_INCREMENT,
  `immate_id`      BIGINT(20),
  `date`           DATE,
  `created_by`     VARCHAR(255)          DEFAULT 'Ray Piao',
  `created_at`     DATETIME              DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`         BIGINT(20),
  `touched_run_id` BIGINT(20),
  `deleted`        TINYINT(1)            DEFAULT '0',
  `md5_hash`       VARCHAR(255),
  PRIMARY KEY (`id`),
  INDEX `fk_parole_booking_dates_inmates_idx` (`immate_id` ASC),
  CONSTRAINT `fk_parole_booking_dates_inmates`
    FOREIGN KEY (`immate_id`)
    REFERENCES `crime_inmate`.`ct_hartfold_inmates` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Ray Piao, Task #842';
