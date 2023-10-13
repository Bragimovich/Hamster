CREATE TABLE `il_la_salle_arrestees`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `full_name`       VARCHAR(255),
  `first_name`      VARCHAR(255),
  `middle_name`     VARCHAR(255),
  `last_name`       VARCHAR(255),
  `suffix`          VARCHAR(255),
  `birthdate`       DATE,
  `age`             INT,
  `age_as_of_date`  INT,
  `race`            VARCHAR(255),
  `sex`             VARCHAR(5),
  `height`          VARCHAR(255),
  `weight`          VARCHAR(255),
  `mugshot`         VARCHAR(1024),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY        `md5` (`md5_hash`),
  INDEX             `run_id` (`run_id`),
  INDEX             `touched_run_id` (`touched_run_id`),
  INDEX             `deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #511';
    
    
CREATE TABLE `il_la_salle_arrestee_ids`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestee_id`     BIGINT,
  `number`          VARCHAR(255),
  `type`            VARCHAR(255),
  `date_from`       DATE,
  `date_to`         DATE,
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY        `md5` (`md5_hash`),
  INDEX             `run_id` (`run_id`),
  INDEX             `touched_run_id` (`touched_run_id`),
  INDEX             `deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #511';
    
    CREATE TABLE `il_la_salle_arrestee_addresses`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestee_id`     BIGINT                                 NULL,
  `full_address`    VARCHAR(255)                           NULL,
  `street_address`  VARCHAR(255)                           NULL,
  `unit_number`     VARCHAR(255)                           NULL,
  `city`            VARCHAR(255)                           NULL,
  `county`          VARCHAR(255)                           NULL,
  `state`           VARCHAR(255)                           NULL,
  `zip`             VARCHAR(255)                           NULL,
  `lan`             VARCHAR(255)                           NULL,
  `lon`             VARCHAR(255)                           NULL,
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY        `md5` (`md5_hash`),
  INDEX             `run_id` (`run_id`),
  INDEX             `touched_run_id` (`touched_run_id`),
  INDEX             `deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #511';
    
    

CREATE TABLE `il_la_salle_arrestee_aliases`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestee_id`     BIGINT,
  `full_name`       VARCHAR(255),
  `first_name`      VARCHAR(255),
  `middle_name`     VARCHAR(255),
  `last_name`       VARCHAR(255),
  `suffix`          VARCHAR(255),
  `data_source_url` TEXT,
  `created_by`      VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`          BIGINT(20),
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY        `md5` (`md5_hash`),
  INDEX             `run_id` (`run_id`),
  INDEX             `touched_run_id` (`touched_run_id`),
  INDEX             `deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #511';
    
    
CREATE TABLE `il_la_salle_arrests`
(
  `id`                      BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrestee_id`             BIGINT(20),
  `status`                  VARCHAR(255),
  `arrest_date`             DATE,
  `booking_date`            DATE,
  `booking_agency`          VARCHAR(255),
  `booking_agency_type`     VARCHAR(255),
  `booking_agency_subtype`  VARCHAR(255),
  `booking_number`          VARCHAR(255),
  `data_source_url`         TEXT,
  `created_by`              VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`              DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                  BIGINT(20),
  `touched_run_id`          BIGINT,
  `deleted`                 BOOLEAN           DEFAULT 0,
  `md5_hash`                VARCHAR(255),
  UNIQUE KEY                `md5` (`md5_hash`),
  INDEX                     `run_id` (`run_id`),
  INDEX                     `touched_run_id` (`touched_run_id`),
  INDEX                     `deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #511';
    
    CREATE TABLE `il_la_salle_charges`
(
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrest_id`           BIGINT(20),
  `number`              VARCHAR(255),
  `disposition`         VARCHAR(255),
  `disposition_date`    DATE,
  `description`         VARCHAR(255),
  `offense_date`        DATE,
  `offense_time`        TIME,
  `attempt_or_commit`   VARCHAR(255),
  `docket_number`       VARCHAR(255),
  `data_source_url`     TEXT,
  `created_by`          VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`              BIGINT(20),
  `touched_run_id`      BIGINT,
  `deleted`             BOOLEAN           DEFAULT 0,
  `md5_hash`            VARCHAR(255),
  UNIQUE KEY            `md5` (`md5_hash`),
  INDEX                 `run_id` (`run_id`),
  INDEX                 `touched_run_id` (`touched_run_id`),
  INDEX                 `deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #511';
    
    CREATE TABLE `il_la_salle_court_hearings`
(
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `charge_id`           BIGINT(20),
  `court_name`          VARCHAR(255),
  `court_date`          DATE,
  `court_time`          TIME,
  `court_room`          VARCHAR(255),
  `case_number`         VARCHAR(255),
  `type`                VARCHAR(255),
  `data_source_url`     TEXT,
  `created_by`          VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`              BIGINT(20),
  `touched_run_id`      BIGINT,
  `deleted`             BOOLEAN           DEFAULT 0,
  `md5_hash`            VARCHAR(255),
  UNIQUE KEY            `md5` (`md5_hash`),
  INDEX                 `run_id` (`run_id`),
  INDEX                 `touched_run_id` (`touched_run_id`),
  INDEX                 `deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #511';
    
    CREATE TABLE `il_la_salle_bonds`
(
  `id`                      BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrest_id`               BIGINT(20),
  `charge_id`               BIGINT(20),
  `bond_category`           VARCHAR(255),
  `bond_number`             VARCHAR(255),
  `bond_type`               VARCHAR(255),
  `bond_amount`             VARCHAR(255),
  `paid`                    INT,
  `made_bond_release_date`  DATE,
  `made_bond_release_time`  TIME,
  `data_source_url`         TEXT,
  `created_by`              VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`              DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                  BIGINT(20),
  `touched_run_id`          BIGINT,
  `deleted`                 BOOLEAN           DEFAULT 0,
  `md5_hash`                VARCHAR(255),
  UNIQUE KEY                `md5` (`md5_hash`),
  INDEX                     `run_id` (`run_id`),
  INDEX                     `touched_run_id` (`touched_run_id`),
  INDEX                     `deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #511';
    
    CREATE TABLE `il_la_salle_holding_facilities`
(
  `id`                      BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrest_id`               BIGINT(20),
  `facility`                VARCHAR(255),
  `facility_type`           VARCHAR(255),
  `facility_subtype`        VARCHAR(255),
  `start_date`              DATE,
  `planned_release_date`    DATE,
  `actual_release_date`     DATE,
  `data_source_url`         TEXT,
  `created_by`              VARCHAR(255)      DEFAULT 'Linnik Victor',
  `created_at`              DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                  BIGINT(20),
  `touched_run_id`          BIGINT,
  `deleted`                 BOOLEAN           DEFAULT 0,
  `md5_hash`                VARCHAR(255),
  UNIQUE KEY                `md5` (`md5_hash`),
  INDEX                     `run_id` (`run_id`),
  INDEX                     `touched_run_id` (`touched_run_id`),
  INDEX                     `deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #511';
    
    
CREATE TABLE `il_la_salle_mugshots`
(
    `id`                      BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `arrestee_id`             BIGINT(20),
    `aws_link`                VARCHAR(255),
    `original_link`           VARCHAR(255),
    `notes`                   VARCHAR(255),
    `data_source_url`         TEXT,
    `created_by`              VARCHAR(255)      DEFAULT 'Linnik Victor',
    `created_at`              DATETIME          DEFAULT CURRENT_TIMESTAMP,
    `updated_at`              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `run_id`                  BIGINT(20),
    `touched_run_id`          BIGINT,
    `deleted`                 BOOLEAN           DEFAULT 0,
    `md5_hash`                VARCHAR(255),
    UNIQUE KEY                `md5` (`md5_hash`),
    INDEX                     `run_id` (`run_id`),
    INDEX                     `touched_run_id` (`touched_run_id`),
    INDEX                     `deleted` (`deleted`)
)   DEFAULT CHARSET = `utf8mb4`
    COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'Created by Victor Linnik, Task #511';
    
    CREATE TABLE `il_la_salle_runs`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `status`          VARCHAR(255)       DEFAULT 'processing',
  `created_by`      VARCHAR(255)       DEFAULT 'Linnik Victor',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
	COMMENT = 'Created by Victor Linnik, Task #511';
  