CREATE TABLE `la_3c_ac_case_info`
(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                BIGINT(20),
  # any columns
  `court_id`              INTEGER           NOT NULL,
  `case_id`               VARCHAR(255)      DEFAULT NULL,
  `case_name`             VARCHAR(255)      DEFAULT NULL,
  `case_filed_date`       DATE,
  `case_type`             VARCHAR(255)      DEFAULT NULL,
  `case_description`      TEXT,
  `disposition_or_status` VARCHAR(255)      DEFAULT NULL,
  `status_as_of_date`     VARCHAR(255)      DEFAULT NULL,
  `judge_name`            VARCHAR(255)      DEFAULT NULL,
  `lower_court_id`        INTEGER           DEFAULT NULL,
  `lower_case_id`         VARCHAR(255)      DEFAULT NULL,
  `data_source_url`       VARCHAR(255),
  `created_by`            VARCHAR(255)      DEFAULT 'Aleksa Gegic',
  `created_at`            DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`        BIGINT,
  `deleted`               BOOLEAN           DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `court_id` (`court_id`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Aleksa Gegic';

CREATE TABLE `la_3c_ac_case_party`
(
  `id`                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`            BIGINT(20),
  # any columns
  `court_id`          INTEGER           NOT NULL,
  `case_id`           VARCHAR(255)      DEFAULT NULL,
  `is_lawyer`         BOOLEAN           NOT NULL,
  `party_name`        VARCHAR(255)      DEFAULT NULL,
  `party_type`        VARCHAR(255)      DEFAULT NULL,
  `party_law_firm`    VARCHAR(255)      DEFAULT NULL,
  `party_address`     VARCHAR(255)      DEFAULT NULL,
  `party_city`        VARCHAR(255)      DEFAULT NULL,
  `party_state`       VARCHAR(255)      DEFAULT NULL,
  `party_zip`         VARCHAR(255)      DEFAULT NULL,
  `party_description` TEXT,
  `data_source_url`   VARCHAR(255),
  `created_by`        VARCHAR(255)      DEFAULT 'Aleksa Gegic',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`    BIGINT,
  `deleted`           BOOLEAN           DEFAULT 0,
  `md5_hash`          VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `court_id` (`court_id`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Aleksa Gegic';

CREATE TABLE `la_3c_ac_case_activities`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  # any columns
  `court_id`        INTEGER           NOT NULL,
  `case_id`         VARCHAR(255)      DEFAULT NULL,
  `activity_date`   DATE,
  `activity_desc`   MEDIUMTEXT        DEFAULT NULL,
  `activity_type`   VARCHAR(255)      DEFAULT NULL,
  `file`            VARCHAR(255)      DEFAULT NULL,
  `data_source_url` VARCHAR(255),
  `created_by`      VARCHAR(255)      DEFAULT 'Aleksa Gegic',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `court_id` (`court_id`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Aleksa Gegic';

CREATE TABLE `la_3c_ac_case_pdfs_on_aws`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  # any columns
  `court_id`        INTEGER           NOT NULL,
  `case_id`         VARCHAR(255)     DEFAULT NULL,
  `source_type`     VARCHAR(255)     DEFAULT NULL,
  `aws_link`        VARCHAR(255)     NOT NULL,
  `source_link`     VARCHAR(255)     DEFAULT NULL,
  `aws_html_link`   VARCHAR(255)     DEFAULT NULL,
  `data_source_url` VARCHAR(255),
  `created_by`      VARCHAR(255)      DEFAULT 'Aleksa Gegic',
  `created_at`      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`  BIGINT,
  `deleted`         BOOLEAN           DEFAULT 0,
  `md5_hash`        VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `court_id` (`court_id`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Aleksa Gegic';

CREATE TABLE `la_3c_ac_case_relations_activity_pdf`
(
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`              BIGINT(20),
  # any columns
  `case_id`             VARCHAR(255)      DEFAULT NULL,
  `case_activities_md5` VARCHAR(4096)     NOT NULL,
  `case_pdf_on_aws_md5` VARCHAR(4096)     NOT NULL,
  `data_source_url`     VARCHAR(255),
  `created_by`          VARCHAR(255)      DEFAULT 'Aleksa Gegic',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`      BIGINT,
  `deleted`             BOOLEAN           DEFAULT 0,
  `md5_hash`            VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Aleksa Gegic';

CREATE TABLE `la_3c_ac_case_additional_info`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`          BIGINT(20),
  # any columns
  `court_id`              INTEGER           NOT NULL,
  `case_id`               VARCHAR(255)      DEFAULT NULL,
  `lower_court_name`      VARCHAR(255)      DEFAULT NULL,
  `lower_case_id`         VARCHAR(255)      DEFAULT NULL,
  `lower_judge_name`      VARCHAR(255)      DEFAULT NULL,
  `lower_judgement_date`  DATE,
  `lower_link`            VARCHAR(255)      DEFAULT NULL,
  `disposition`           VARCHAR(255)      DEFAULT NULL,
  `data_source_url`       VARCHAR(255),
  `created_by`            VARCHAR(255)      DEFAULT 'Aleksa Gegic',
  `created_at`            DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`        BIGINT,
  `deleted`               BOOLEAN           DEFAULT 0,
  `md5_hash`              VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `court_id` (`court_id`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'The Scrape made by Aleksa Gegic';
