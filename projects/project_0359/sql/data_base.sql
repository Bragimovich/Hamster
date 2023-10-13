CREATE TABLE `il_professional_licenses__csv`
(
  `id`                    BIGINT(20)    AUTO_INCREMENT PRIMARY KEY,
  `run_id`                BIGINT(20),
  # BEGIN scrape 359
  `license_type`                            VARCHAR(255)  NOT NULL,
  `description`                             VARCHAR(255)  NOT NULL,
  `license_number`                          VARCHAR(255)  NOT NULL,
  `status`                                  VARCHAR(255)  NOT NULL,
  `business`                                BOOLEAN       NOT NULL,
  `title`                                   VARCHAR(255)  DEFAULT NULL,
  `first_name`                              VARCHAR(255)  DEFAULT NULL,
  `middle_name`                             VARCHAR(255)  DEFAULT NULL,
  `last_name`                               VARCHAR(255)  DEFAULT NULL,
  `prefix`                                  VARCHAR(255)  DEFAULT NULL,
  `suffix`                                  VARCHAR(255)  DEFAULT NULL,
  `busines_name`                            VARCHAR(255)  DEFAULT NULL,
  `busines_dba`                             VARCHAR(255)  DEFAULT NULL,
  `original_date`                           DATE          DEFAULT NULL,
  `effective_date`                          DATE          DEFAULT NULL,
  `expiration_date`                         DATE          DEFAULT NULL,
  `city`                                    VARCHAR(255)  DEFAULT NULL,
  `state`                                   VARCHAR(255)  DEFAULT NULL,
  `zip`                                     VARCHAR(255)  DEFAULT NULL,
  `county`                                  VARCHAR(255)  DEFAULT NULL,
  `speciality`                              VARCHAR(255)  DEFAULT NULL,
  `controlled_substance_schedule`           VARCHAR(255)  DEFAULT NULL,
  `delegated_controlled_substance_schedule` VARCHAR(255)  DEFAULT NULL,
  `ever_disciplined`                        BOOLEAN       NOT NULL,
  `last_modified_date`                      DATE          NOT NULL,
  `discipline_case_number`                  VARCHAR(255)  DEFAULT NULL,
  `discipline_action`                       VARCHAR(255)  DEFAULT NULL,
  `discipline_start_date`                   DATE          DEFAULT NULL,
  `discipline_end_date`                     DATE          DEFAULT NULL,
  `discipline_reason`                       TEXT          DEFAULT NULL,
  # END
  `data_source_url`                         VARCHAR(255)  DEFAULT 'https://data.illinois.gov/datastore/dump/63d9a971-fbba-4144-8ba9-8752112b7f4d',
  `created_by`                              VARCHAR(255)  DEFAULT 'Oleksii Kuts',
  `created_at`                              DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                              TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`                          BIGINT,
  `deleted`                                 BOOLEAN       DEFAULT 0,
  `md5_hash`                                VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Illinois professional licenses from https://data.illinois.gov/dataset/professional-licensing`...., Created by Oleksii Kuts, Task #359';

CREATE TABLE `il_professional_licenses__runs`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `status`          VARCHAR(255)       DEFAULT  'processing',
    `created_by`      VARCHAR(255)       DEFAULT 'Oleksii Kuts',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Illinois professional licenses from https://data.illinois.gov/dataset/professional-licensing`...., Created by Oleksii Kuts, Task #359';
