CREATE TABLE IF NOT EXISTS `NV_RAW_Expenses` (
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `expense_id`          INT,
  `report_id`           INT,
  `candidate_id`        INT,
  `group_id`            INT,
  `expense_date`        DATE,
  `expense_amount`      DECIMAL(10, 2),
  `expense_type`        VARCHAR(255),
  `payee_id`            INT,

  `data_source_url`     TEXT,
  `run_id`              BIGINT,
  `touched_run_id`      BIGINT,
  `deleted`             BOOLEAN           DEFAULT 0,
  `md5_hash`            VARCHAR(45),
  `created_by`          VARCHAR(45)       DEFAULT 'Gabriel Carvalho',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `NV_RAW_Contributions` (
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `contribution_id`     INT,
  `report_id`           INT,
  `candidate_id`        INT,
  `group_id`            INT,
  `contribution_date`   DATE,
  `contribution_amount` DECIMAL(10, 2),
  `contribution_type`   VARCHAR(255),
  `contributor_id`      INT,

  `data_source_url`     TEXT,
  `run_id`              BIGINT,
  `touched_run_id`      BIGINT,
  `deleted`             BOOLEAN           DEFAULT 0,
  `md5_hash`            VARCHAR(45),
  `created_by`          VARCHAR(45)       DEFAULT 'Gabriel Carvalho',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;


CREATE TABLE IF NOT EXISTS `NV_RAW_Contributors` (
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `contact_id`          INT,
  `first_name`          VARCHAR(255),
  `middle_name`         VARCHAR(255),
  `last_name`           VARCHAR(255),
  `address_1`           VARCHAR(255),
  `address_2`           VARCHAR(255),
  `city`                VARCHAR(255),
  `state`               VARCHAR(255),
  `zip`                 VARCHAR(10),
  
  `data_source_url`     TEXT,
  `run_id`              BIGINT,
  `touched_run_id`      BIGINT,
  `deleted`             BOOLEAN           DEFAULT 0,
  `md5_hash`            VARCHAR(45),
  `created_by`          VARCHAR(45)       DEFAULT 'Gabriel Carvalho',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `NV_RAW_Reports` (
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `report_id`           INT,
  `candidate_id`        INT,
  `group_id`            INT,
  `report_name`         VARCHAR(255),
  `election_cycle`      VARCHAR(255),
  `filing_due_date`     DATE,
  `filed_date`          DATE,
  `amended`             BOOLEAN,
  `superseded`          BOOLEAN,

  `data_source_url`     TEXT,
  `run_id`              BIGINT,
  `touched_run_id`      BIGINT,
  `deleted`             BOOLEAN           DEFAULT 0,
  `md5_hash`            VARCHAR(45),
  `created_by`          VARCHAR(45)       DEFAULT 'Gabriel Carvalho',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `NV_RAW_Candidates` (
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `candidate_id`        INT,
  `first_name`          VARCHAR(255),
  `last_name`           VARCHAR(255),
  `party`               VARCHAR(255),
  `office`              VARCHAR(255),
  `jurisdiction`        VARCHAR(255),
  `mailing_address`     VARCHAR(255),
  `mailing_city`        VARCHAR(255),
  `mailing_state`       VARCHAR(255),
  `mailing_zip`         VARCHAR(10),

  `data_source_url`     TEXT,
  `run_id`              BIGINT,
  `touched_run_id`      BIGINT,
  `deleted`             BOOLEAN           DEFAULT 0,
  `md5_hash`            VARCHAR(45),
  `created_by`          VARCHAR(45)       DEFAULT 'Gabriel Carvalho',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `NV_RAW_Groups` (
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `group_id`            INT,
  `group_name`          VARCHAR(255),
  `group_type`          VARCHAR(255),
  `contact_name`        VARCHAR(255),
  `active`              BOOLEAN,
  `city`                VARCHAR(255),

  `data_source_url`     TEXT,
  `run_id`              BIGINT,
  `touched_run_id`      BIGINT,
  `deleted`             BOOLEAN           DEFAULT 0,
  `md5_hash`            VARCHAR(45),
  `created_by`          VARCHAR(45)       DEFAULT 'Gabriel Carvalho',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `NV_RAW_RUNS` (
  `id`                BIGINT AUTO_INCREMENT PRIMARY KEY,
  `status`            VARCHAR(45) DEFAULT 'in progress',

  `created_by`        VARCHAR(45)       DEFAULT 'Gabriel Carvalho',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE INDEX `id_UNIQUE` (`id` ASC)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci;
