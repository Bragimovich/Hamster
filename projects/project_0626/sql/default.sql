CREATE TABLE `ct_court__jud_ct_gov`
(
  `id`                                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `bar_number`                        VARCHAR(255) NULL,
  `name`                              VARCHAR(255) NULL,
  `first_name`                        VARCHAR(255) NULL,
  `last_name`                         VARCHAR(255) NULL,
  `middle_name`                       VARCHAR(255) NULL,
  `date_admited`                      DATE         NULL,
  `registration_status`               VARCHAR(255) NULL,
  `sections`                          TEXT         NULL,
  `type`                              VARCHAR(255) NULL,
  `phone`                             VARCHAR(255) NULL,
  `email`                             VARCHAR(255) NULL,
  `fax`                               VARCHAR(255) NULL,
  `raw_address`						            VARCHAR(255) NULL,
  `law_firm_name`                     VARCHAR(255) NULL,
  `law_firm_address`                  VARCHAR(255) NULL,
  `law_firm_zip`                      VARCHAR(255) NULL,
  `law_firm_city`                     VARCHAR(255) NULL,
  `law_firm_state`                    VARCHAR(255) NULL,
  `law_firm_county`                   VARCHAR(255) NULL,
  `law_firm_country`				          VARCHAR(255) NULL,
  `name_prefix`                       VARCHAR(255) NULL,
  `university`                        VARCHAR(255) NULL,
  `professional_affiliation`          TEXT         NULL,
  `bio`                               LONGTEXT     NULL,
  `website`                           VARCHAR(255) NULL,
  `linkedin`                          VARCHAR(255) NULL,
  `facebook`                          VARCHAR(255) NULL,
  `twitter`                           VARCHAR(255) NULL,
  `law_firm_website`                  VARCHAR(255) NULL,
  `other_jurisdictions`               TEXT         NULL,
  `judicial_district`                 VARCHAR(255) NULL,
  `disciplinary_actions`              TEXT         NULL,
  `private_practice`                  VARCHAR(255) NULL,
  `insurance`                         VARCHAR(255) NULL,
  `courts_of_admittance`              VARCHAR(255) NULL,
  `scrape_frequency`                  VARCHAR(255)       DEFAULT 'weekly',
  `data_source_url`                   VARCHAR(255),
  `created_by`                        VARCHAR(255)       DEFAULT 'Victor Linnik',
  `created_at`                        DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `run_id`                            BIGINT(20),
  `touched_run_id`                    BIGINT,
  `deleted`                           BOOLEAN            DEFAULT 0,
  `md5_hash`                          VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Created by Victor Linnik, Task #626';

    CREATE TABLE `ct_court__jud_ct_gov_runs`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `status`          VARCHAR(255)       DEFAULT 'processing',
  `created_by`      VARCHAR(255)       DEFAULT 'Linnik Victor',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
	COMMENT = 'Created by Victor Linnik, Task #626';
