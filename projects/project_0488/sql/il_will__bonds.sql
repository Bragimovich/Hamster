CREATE TABLE `il_will__bonds`
(
  `id`                         BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `arrest_id`                  BIGINT(20),
  `charge_id`                  BIGINT(20),
  `bond_category`              VARCHAR(255) DEFAULT NULL,
  `bond_number`                VARCHAR(255) DEFAULT NULL,
  `bond_type`                  VARCHAR(255) DEFAULT NULL,
  `bond_amount`                VARCHAR(255) DEFAULT NULL,
  `paid`                       TINYINT(1) DEFAULT NULL,
  `made_bond_release_date`     DATE,
  `made_bond_release_time`     TIME,
  `data_source_url`            VARCHAR(255) DEFAULT NULL,
  `created_by`                 VARCHAR(255)       DEFAULT 'Andrey Tereshchenko',
  `created_at`                 DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                 TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                     BIGINT DEFAULT NULL,
  `touched_run_id`             BIGINT DEFAULT NULL,
  `deleted`                    BOOLEAN            DEFAULT 0,
  `md5_hash`                   VARCHAR(255),
  INDEX `md5_hash` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
