USE `us_court_cases`;

CREATE TABLE `OHSD_courts` # Ohio Southern District
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`          BIGINT(20),
    `court_id`        VARCHAR(255),
    `court_name`      VARCHAR(255)       DEFAULT 'District Court for the Southern District of Ohio',
    `court_state`     VARCHAR(255)       DEFAULT 'OH',
    `court_type`      VARCHAR(255)       DEFAULT 'Federal',
    `court_sub_type`  VARCHAR(255)       DEFAULT 'District',
    `data_source_url` TEXT,
    `created_by`      VARCHAR(255)       DEFAULT 'Anton Storchak',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`  BIGINT,
    `deleted`         BOOLEAN            DEFAULT 0,
    `md5_hash`        VARCHAR(255),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE `OHSD_case_lawyer`
(
    `id`                               BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                           BIGINT(20),
    `court_id`                         VARCHAR(255),
    `case_id`                          VARCHAR(255),
    `defendant_lawyer`                 VARCHAR(255),
    `defendant_lawyer_firm`            VARCHAR(255),
    `defendant_lawyer_additional_data` TEXT,
    `plantiff_lawyer`                  VARCHAR(255),
    `plantiff_lawyer_firm`             VARCHAR(255),
    `plantiff_lawyer_additional_data`  TEXT,
    `data_source_url`                  TEXT,
    `scrape_frequency`                 VARCHAR(255)       DEFAULT 'daily',
    `created_by`                       VARCHAR(255)       DEFAULT 'Anton Storchak',
    `created_at`                       DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`                   BIGINT,
    `deleted`                          BOOLEAN            DEFAULT 0,
    `md5_hash`                         VARCHAR(255),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE `OHSD_case_party`
(
    `id`                     BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                 BIGINT(20),
    `court_id`               VARCHAR(255) NOT NULL,
    `case_id`                VARCHAR(255) NOT NULL,
    `party_name`             VARCHAR(255) NOT NULL,
    `party_type`             VARCHAR(255) NOT NULL,
    `party_address`          VARCHAR(255) NOT NULL,
    `party_city`             VARCHAR(255) NOT NULL,
    `party_state`            VARCHAR(255) NOT NULL,
    `party_zip`              VARCHAR(255) NOT NULL,
    `law_firm`               VARCHAR(255) NOT NULL,
    `lawyer_additional_data` TEXT NOT NULL,
    `party_description`      TEXT,
    `is_lawyer`              BOOLEAN NOT NULL,
    `data_source_url`        TEXT,
    `scrape_frequency`       VARCHAR(255)       DEFAULT 'daily',
    `created_by`             VARCHAR(255)       DEFAULT 'Anton Storchak',
    `created_at`             DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`         BIGINT,
    `deleted`                BOOLEAN            DEFAULT 0,
    `md5_hash`               VARCHAR(255),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE `OHSD_case_info`
(
    `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                BIGINT(20),
    `court_id`              VARCHAR(255),
    `case_name`             VARCHAR(255),
    `case_id`               VARCHAR(255),
    `case_filed_date`       VARCHAR(255),
    `case_description`      TEXT,
    `case_type`             VARCHAR(255),
    `disposition_or_status` VARCHAR(255),
    `status_as_of_date`     VARCHAR(255),
    `judge_name`            VARCHAR(255),
    `data_source_url`       TEXT,
    `scrape_frequency`      VARCHAR(255)       DEFAULT 'daily',
    `created_by`            VARCHAR(255)       DEFAULT 'Anton Storchak',
    `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`        BIGINT,
    `deleted`               BOOLEAN            DEFAULT 0,
    `md5_hash`              VARCHAR(255),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE `OHSD_case_activities`
(
    `id`               BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`           BIGINT(20),
    `court_id`         VARCHAR(255),
    `case_id`          VARCHAR(255),
    `activity_date`    VARCHAR(255),
    `activity_decs`    TEXT,
    `activity_pdf`     VARCHAR(255),
    `data_source_url`  TEXT,
    `scrape_frequency` VARCHAR(255)       DEFAULT 'daily',
    `created_by`       VARCHAR(255)       DEFAULT 'Anton Storchak',
    `created_at`       DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `touched_run_id`   BIGINT,
    `deleted`          BOOLEAN            DEFAULT 0,
    `md5_hash`         VARCHAR(255),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE `OHSD_runs`
(
    `id`                 BIGINT AUTO_INCREMENT PRIMARY KEY,
    `status`             VARCHAR(255)       DEFAULT 'processing',
    `downloading_status` VARCHAR(255)       DEFAULT 'processing',
    `storing_status`     VARCHAR(255)       DEFAULT 'waiting',
    `created_by`         VARCHAR(255)       DEFAULT 'Anton Storchak',
    `created_at`         DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `status_idx` (`status`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;