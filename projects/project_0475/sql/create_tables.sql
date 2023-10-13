======================================================
CREATE TABLE `sc_bar_scbar_org__runs`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `status`          VARCHAR(255)       DEFAULT  'processing',
    `created_by`      VARCHAR(255)       DEFAULT 'Oleksii Kuts',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Runs for `Lawyers from scbar.org`...., Created by Oleksii Kuts, Task #475';
======================================================
CREATE TABLE `sc_bar_scbar_org`
(
  `id`                       BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  `run_id`                   BIGINT(20),
  # begin
  `bar_number`               varchar(255)   null,
  `name`                     varchar(255)   null,
  `first_name`               varchar(255)   null,
  `last_name`                varchar(255)   null,
  `middle_name`              varchar(255)   null,
  `date_admited`             date           null,
  `registration_status`      varchar(255)   null,
  `sections`                 text           null,
  `type`                     varchar(255)   null,
  `phone`                    varchar(255)   null,
  `email`                    varchar(255)   null,
  `fax`                      varchar(255)   null,
  `law_firm_name`            varchar(255)   null,
  `law_firm_address`         varchar(255)   null,
  `law_firm_zip`             varchar(255)   null,
  `law_firm_city`            varchar(255)   null,
  `law_firm_state`           varchar(255)   null,
  `law_firm_county`          varchar(255)   null,
  `name_prefix`              varchar(255)   null,
  `university`               varchar(255)   null,
  `professional_affiliation` text           null,
  `bio`                      longtext       null,
  `website`                  varchar(255)   null,
  `linkedin`                 varchar(255)   null,
  `facebook`                 varchar(255)   null,
  `twitter`                  varchar(255)   null,
  `law_firm_website`         varchar(255)   null,
  `other_jurisdictions`      text           null,
  `judicial_district`        varchar(255)   null,
  `disciplinary_actions`     text           null,
  `private_practice`         varchar(255)   null,
  `insurance`                varchar(255)   null,
  `courts_of_admittance`     varchar(255)   null,
  `scrape_frequency`         varchar(255)   default 'weekly',
  # end
  `data_source_url`          TEXT           NOT NULL,
  `created_by`               VARCHAR(255)            DEFAULT 'Oleksii Kuts',
  `created_at`               DATETIME                DEFAULT CURRENT_TIMESTAMP,
  `updated_at`               DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`           BIGINT,
  `deleted`                  BOOLEAN                DEFAULT 0,
  `md5_hash`                 VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Lawyers from scbar.org...., Created by Oleksii Kuts, Task #475';
