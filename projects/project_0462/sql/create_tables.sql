CREATE TABLE `opensecrets__organizations`
(
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  # any columns
  `org_id`              VARCHAR(20),
  `orgname`             VARCHAR(100),

  `data_source_url`     TEXT,
  `created_by`          VARCHAR(255)      DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `org_id_key` (`org_id`),
  INDEX `org_id` (`org_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
====================================================================
CREATE TABLE `opensecrets__contributions_by_party_of_recipient`
(
  `id`                  BIGINT(20)  AUTO_INCREMENT PRIMARY KEY,
  `donor_id`            VARCHAR(10) NOT NULL,
  `cycle`               INT         NOT NULL,
  `total`               INT         NOT NULL,
  `to_democrats`        INT         NOT NULL,
  `percent_to_dems`     FLOAT(6,2)  NOT NULL,
  `to_republicans`      INT         NOT NULL,
  `percent_to_repubs`   FLOAT(6,2)  NOT NULL,

  `data_source_url`     VARCHAR(255)NOT NULL,
  `created_by`          VARCHAR(255)      DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `donor_id` (`donor_id`, `cycle`),
  INDEX `donor` (`donor_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Created by Oleksii Kuts, all donors(organizations) total contributions by party of recipient';
====================================================================
CREATE TABLE `opensecrets__contributions_by_source_of_funds`
(
  `id`                  BIGINT(20)  AUTO_INCREMENT PRIMARY KEY,
  `donor_id`            VARCHAR(10) NOT NULL,
  `cycle`               INT         NOT NULL,
  `individuals`         INT         NOT NULL,
  `pacs`                INT         NOT NULL,
  `soft_individuals`    INT         NOT NULL,
  `soft_organizations`  INT         NOT NULL,

  `data_source_url`     VARCHAR(255)NOT NULL,
  `created_by`          VARCHAR(255)      DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `donor_id` (`donor_id`, `cycle`),
  INDEX `donor` (`donor_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Created by Oleksii Kuts, all donors(organizations) total contributions by source of funds';
====================================================================
CREATE TABLE `opensecrets__affiliates`
(
  `id`                  BIGINT(20)  AUTO_INCREMENT PRIMARY KEY,
  `donor_id`            VARCHAR(10) NOT NULL,
  `affiliate`           VARCHAR(255)NOT NULL,
  `total`               INT         NOT NULL,
  `to_democrats`        INT         NOT NULL,
  `percent_to_dems`     FLOAT(5,2)  NOT NULL,
  `to_republicans`      INT         NOT NULL,
  `percent_to_repubs`   FLOAT(5,2)  NOT NULL,
  `pacs`                INT         NOT NULL COMMENT 'Contributions from political action committees, which raise money from individuals on behalf of business, labor or ideological interests and contribute directly to candidates and parties.',
  `individuals`         INT         NOT NULL COMMENT 'Contributions from members, employees or owners of the organization, and those individuals’ immediate family members.',
  `cycle`               INT         NOT NULL,

  `data_source_url`     VARCHAR(255)NOT NULL,
  `created_by`          VARCHAR(255)      DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `donor_id` (`donor_id`, `affiliate`, `period`),
  INDEX `donor` (`donor_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = "Created by Oleksii Kuts, every donor's affiliates. Only affiliates that have given money are included in this list";
====================================================================
CREATE TABLE `opensecrets__recipients`
(
  `id`                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  # any columns
  `donor_id`          VARCHAR(20),
  `recipient`         VARCHAR(100),
  `total`             INT,
  `from_individuals`  INT,
  `from_organization` INT,
  `recipient_type`    VARCHAR(30),
  `view`              VARCHAR(20),
  `record_type`       VARCHAR(10),
  `chamber`           VARCHAR(10),
  `cycle`             INT         NOT NULL,

  `data_source_url`   TEXT,
  `created_by`        VARCHAR(255)      DEFAULT 'Oleksii Kuts',
  `created_at`        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

ALTER TABLE `opensecrets__recipients`
ADD UNIQUE (donor_id, recipient, total, recipient_type, view, record_type, chamber, cycle);

CREATE TABLE `opensecrets__top_recipients` LIKE `opensecrets__recipients`;
====================================================================
CREATE TABLE `opensecrets__candidates`
(
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `cid`                 VARCHAR(10) NOT NULL,
  `crp_name`            VARCHAR(255) NOT NULL,
  `party`               VARCHAR(1) NOT NULL,
  `dist_id_run_for`     VARCHAR(4) NOT NULL,
  `fec_cand_id`         VARCHAR(10) NOT NULL,

  `data_source_url`     VARCHAR(255)      DEFAULT 'https://www.opensecrets.org/downloads/crp/CRP_IDs.xls',
  `created_by`          VARCHAR(255)      DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `candidate_id` (`cid`),
  INDEX `cid` (`cid`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Created by Oleksii Kuts, all candidates(recipients) raw data from https://www.opensecrets.org/downloads/crp/CRP_IDs.xls';

LOAD DATA LOCAL INFILE '/home/developer/tmp/store/Candidates.csv'
    INTO TABLE `opensecrets__candidates`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (@p1, @p2, @p3, @p4, @p5)
    SET cid = @p1,
        crp_name        = @p2,
        party           = @p3,
        dist_id_run_for = @p4,
        fec_cand_id     = @p5;

CREATE TABLE `opensecrets__organization_donors`
(
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  # any columns
  `donor_id`            VARCHAR(20),
  `rank`                INT,
  `organization`        VARCHAR(100),
  `total_contributions` INT,
  `total_hard_money`    INT,
  `total_outside_money` INT,
  `to_democrats`        INT,
  `to_republicans`      INT,
  `lean`                VARCHAR(50),
  `cycle`               VARCHAR(12),

  `data_source_url`     TEXT,
  `created_by`          VARCHAR(255)      DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `donor_id` (`donor_id`, `cycle`),
  INDEX `donor` (`donor_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Created by Oleksii Kuts, all top_donors data, 51 per cycle';
