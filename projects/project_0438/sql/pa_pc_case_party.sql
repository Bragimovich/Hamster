CREATE TABLE `pa_pc_case_party`
(
  `id`                    BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `court_id`              SMALLINT           DEFAULT NULL,
  `case_id`               VARCHAR(100)       DEFAULT NULL,

  `is_lawyer`             TINYINT(1)         DEFAULT 0,
  `party_name`            VARCHAR(255)       DEFAULT NULL,
  `party_type`            VARCHAR(100)       DEFAULT NULL,
  `law_firm`              VARCHAR(150)       DEFAULT NULL,
  `party_address`         VARCHAR(255)       DEFAULT NULL,
  `party_city`            VARCHAR(150)       DEFAULT NULL,
  `party_state`           VARCHAR(3)         DEFAULT NULL,
  `party_zip`             VARCHAR(50)        DEFAULT NULL,
  `party_description`     VARCHAR(255)       DEFAULT NULL,

  `data_source_url`       VARCHAR(255)       DEFAULT NULL,
  `md5_hash`              VARCHAR(32)        DEFAULT NULL,
  `run_id`                BIGINT(20)         DEFAULT NULL,
  `touched_run_id`        BIGINT(20)         DEFAULT NULL,
  `deleted`               TINYINT(1)         DEFAULT 0,

  `created_by`            VARCHAR(20)        DEFAULT 'Eldar Eminov',
  `created_at`            DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `md5_hash` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
