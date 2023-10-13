CREATE TABLE `wv_sc_case_party`
(
    `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `run_id`                BIGINT(20),
    `court_id`              SMALLINT           DEFAULT NULL,
    `case_id`               VARCHAR(100)       DEFAULT NULL,

    `is_lawyer`             BOOLEAN            DEFAULT 0,
    `party_name`            VARCHAR(100)       DEFAULT NULL,
    `party_type`            VARCHAR(100)       DEFAULT NULL,
    `party_law_firm`        VARCHAR(100)       DEFAULT NULL,
    `party_address`         VARCHAR(100)       DEFAULT NULL,
    `party_city`            VARCHAR(100)       DEFAULT NULL,
    `party_state`           VARCHAR(100)       DEFAULT NULL,
    `party_zip`             VARCHAR(100)       DEFAULT NULL,
    `party_description`     VARCHAR(100)       DEFAULT NULL,

    `data_source_url`       VARCHAR(255)       DEFAULT NULL,
    `deleted`               BOOLEAN            DEFAULT 0,
    `md5_hash`              VARCHAR(32)        DEFAULT NULL,
    `created_by`            VARCHAR(20)        DEFAULT 'Farzpal Singh',
    `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `md5_hash` (`md5_hash`)
    INDEX `court_id` (`court_id`),
    INDEX `deleted` (`deleted`),
    INDEX `md5_hash` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
  COMMENT = 'Created by Farzpal Singh, Task #0564';
