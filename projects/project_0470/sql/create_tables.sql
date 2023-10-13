======================================================
CREATE TABLE `cl_runs`
(
    `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `status`          VARCHAR(255)       DEFAULT  'processing',
    `created_by`      VARCHAR(255)       DEFAULT 'Oleksii Kuts',
    `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
======================================================
CREATE TABLE `cl_clusters`
(
  `id`                        BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  # begin
  `cluster_id`                INT,
  `absolute_url`              VARCHAR(255),
  `panel`                     TEXT,
  `non_participating_judges`  TEXT,
  `docket_id`                 INT,
  `sub_opinions`              TEXT,
  `citations`                 TEXT,
  `date_created`              DATETIME,
  `date_modified`             DATETIME,
  `judges`                    TEXT,
  `date_filed`                DATE,
  `date_filed_is_approximate` CHAR(1),
  `slug`                      VARCHAR(255),
  `case_name_short`           VARCHAR(3000),
  `case_name`                 TEXT,
  `case_name_full`            MEDIUMTEXT,
  `scdb_id`                   VARCHAR(255),
  `scdb_decision_direction`   INT,
  `scdb_votes_majority`       INT,
  `scdb_votes_minority`       INT,
  `source`                    VARCHAR(10),
  `procedural_history`        VARCHAR(25),
  `attorneys`                 MEDIUMTEXT,
  `nature_of_suit`            TEXT,
  `posture`                   MEDIUMTEXT,
  `syllabus`                  TEXT,
  `headnotes`                 TEXT,
  `summary`                   MEDIUMTEXT,
  `disposition`               TEXT,
  `history`                   TEXT,
  `other_dates`               VARCHAR(1500),
  `cross_reference`           VARCHAR(1500),
  `correction`                TEXT,
  `citation_count`            INT,
  `precedential_status`       VARCHAR(255),
  `date_blocked`              DATE,
  `blocked`                   CHAR(1),
  # end
  `data_source_url`           TEXT          NOT NULL,
  `created_by`                VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`                DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`                   BOOLEAN                DEFAULT 0,
  UNIQUE KEY `cluster_modified_id` (`cluster_id`, `date_modified`),
  INDEX `cluster` (`cluster_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Clusters from CourtListener.com...., Created by Oleksii Kuts, Task #470';

INSERT INTO `cl_clusters`
(SELECT
  null,
  id,
  null,
  null,
  null,
  docket_id,
  null,
  null,
  date_created,
  date_modified,
  judges,
  date_filed,
  date_filed_is_approximate,
  slug,
  case_name_short,
  case_name,
  case_name_full,
  scdb_id,
  scdb_decision_direction,
  scdb_votes_majority,
  scdb_votes_minority,
  source,
  procedural_history,
  attorneys,
  nature_of_suit,
  posture,
  syllabus,
  headnotes,
  summary,
  disposition,
  history,
  other_dates,
  cross_reference,
  correction,
  citation_count,
  precedential_status,
  date_blocked,
  blocked,
  'cl_csv_clusters, bulk data from https://com-courtlistener-storage.s3-us-west-2.amazonaws.com/list.html?prefix=bulk-data/',
  'Oleksii Kuts',
  current_timestamp(),
  current_timestamp(),
  0 as deleted
FROM `cl_csv_clusters` order by id desc limit 1);

CREATE TABLE `cl_raw_clusters`
(
  # begin
  `cluster_id`                INT,
  `absolute_url`              VARCHAR(255),
  `panel`                     TEXT,
  `non_participating_judges`  TEXT,
  `docket_id`                 INT,
  `sub_opinions`              TEXT,
  `citations`                 TEXT,
  `date_created`              DATETIME,
  `date_modified`             DATETIME,
  `judges`                    TEXT,
  `date_filed`                DATE,
  `date_filed_is_approximate` CHAR(1),
  `slug`                      VARCHAR(255),
  `case_name_short`           VARCHAR(3000),
  `case_name`                 TEXT,
  `case_name_full`            MEDIUMTEXT,
  `scdb_id`                   VARCHAR(255),
  `scdb_decision_direction`   INT,
  `scdb_votes_majority`       INT,
  `scdb_votes_minority`       INT,
  `source`                    VARCHAR(10),
  `procedural_history`        VARCHAR(25),
  `attorneys`                 MEDIUMTEXT,
  `nature_of_suit`            TEXT,
  `posture`                   MEDIUMTEXT,
  `syllabus`                  TEXT,
  `headnotes`                 TEXT,
  `summary`                   MEDIUMTEXT,
  `disposition`               TEXT,
  `history`                   TEXT,
  `other_dates`               VARCHAR(1500),
  `cross_reference`           VARCHAR(1500),
  `correction`                TEXT,
  `citation_count`            INT,
  `precedential_status`       VARCHAR(255),
  `date_blocked`              DATE,
  `blocked`                   CHAR(1),
  # end
  `data_source_url`           TEXT          NOT NULL,
  `created_by`                VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`                DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `cluster_id` (`cluster_id`),
  INDEX `cluster` (`cluster_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Clusters from CourtListener.com...., Created by Oleksii Kuts, Task #470';
======================================================
CREATE TABLE `cl_dockets`
(
  `id`                  BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  # begin
  `docket_id`                         BIGINT(20),
  `court_id`                          VARCHAR(30),
  `originating_court_information_id`  BIGINT(20),
  `idb_data_id`                       BIGINT(20),
  `clusters`                          TEXT,
  `audio_files`                       TEXT,
  `assigned_to_id`                    BIGINT(20),
  `referred_to_id`                    BIGINT(20),
  `absolute_url`                      VARCHAR(170),
  `date_created`                      DATETIME,
  `date_modified`                     DATETIME,
  `source`                            BIGINT(20),
  `appeal_from_str`                   VARCHAR(200),
  `assigned_to_str`                   VARCHAR(100),
  `referred_to_str`                   TEXT,
  `panel_str`                         VARCHAR(100),
  `date_last_index`                   DATETIME,
  `date_cert_granted`                 DATE,
  `date_cert_denied`                  DATE,
  `date_argued`                       DATE,
  `date_reargued`                     DATE,
  `date_reargument_denied`            DATE,
  `date_filed`                        DATE,
  `date_terminated`                   DATE,
  `date_last_filing`                  DATE,
  `case_name_short`                   VARCHAR(500),
  `case_name`                         TEXT,
  `case_name_full`                    MEDIUMTEXT,
  `slug`                              VARCHAR(150),
  `docket_number`                     VARCHAR(750),
  `docket_number_core`                BIGINT(20),
  `pacer_case_id`                     BIGINT(20),
  `cause`                             TEXT,
  `nature_of_suit`                    VARCHAR(1000),
  `jury_demand`                       VARCHAR(255),
  `jurisdiction_type`                 VARCHAR(50),
  `appellate_fee_status`              VARCHAR(40),
  `appellate_case_type_information`   VARCHAR(150),
  `mdl_status`                        VARCHAR(40),
  `filepath_ia`                       VARCHAR(200),
  `filepath_ia_json`                  VARCHAR(200),
  `ia_upload_failure_count`           BIGINT(20),
  `ia_needs_upload`                   char(1),
  `ia_date_first_change`              DATETIME,
  `date_blocked`                      DATE,
  `blocked`                           char(1),
  `appeal_from_id`                    BIGINT(20),
  `tags`                              TEXT,
  `panel`                             TEXT,
  # end
  `data_source_url`     TEXT          NOT NULL,
  `created_by`          VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`                           BOOLEAN                DEFAULT 0,
  UNIQUE KEY `docket_modified_id` (`docket_id`, `date_modified`),
  INDEX `docket` (`docket_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Dockets from CourtListener.com...., Created by Oleksii Kuts, Task #470';

INSERT INTO `cl_dockets`
(SELECT
  null,
  id,
  court_id,
  originating_court_information_id,
  idb_data_id,
  null,
  null,
  assigned_to_id,
  referred_to_id,
  null,
  date_created,
  date_modified,
  source,
  appeal_from_str,
  assigned_to_str,
  referred_to_str,
  panel_str,
  null,
  date_cert_granted,
  date_cert_denied,
  date_argued,
  date_reargued,
  date_reargument_denied,
  date_filed,
  date_terminated,
  date_last_filing,
  case_name_short,
  case_name,
  case_name_full,
  slug,
  docket_number,
  docket_number_core,
  pacer_case_id,
  cause,
  nature_of_suit,
  jury_demand,
  jurisdiction_type,
  appellate_fee_status,
  appellate_case_type_information,
  mdl_status,
  filepath_ia,
  filepath_ia_json,
  null,
  null,
  null,
  date_blocked,
  blocked,
  appeal_from_id,
  null,
  null,
  'cl_csv_dockets, bulk data from https://com-courtlistener-storage.s3-us-west-2.amazonaws.com/list.html?prefix=bulk-data/',
  'Oleksii Kuts',
  current_timestamp(),
  current_timestamp(),
  0 as deleted
FROM `cl_csv_dockets` order by id desc limit 1);

CREATE TABLE `cl_raw_dockets`
(
  # begin
  `docket_id`                         BIGINT(20),
  `court_id`                          VARCHAR(30),
  `originating_court_information_id`  BIGINT(20),
  `idb_data_id`                       BIGINT(20),
  `clusters`                          TEXT,
  `audio_files`                       TEXT,
  `assigned_to_id`                    BIGINT(20),
  `referred_to_id`                    BIGINT(20),
  `absolute_url`                      VARCHAR(170),
  `date_created`                      DATETIME,
  `date_modified`                     DATETIME,
  `source`                            BIGINT(20),
  `appeal_from_str`                   VARCHAR(200),
  `assigned_to_str`                   VARCHAR(100),
  `referred_to_str`                   TEXT,
  `panel_str`                         VARCHAR(100),
  `date_last_index`                   DATETIME,
  `date_cert_granted`                 DATE,
  `date_cert_denied`                  DATE,
  `date_argued`                       DATE,
  `date_reargued`                     DATE,
  `date_reargument_denied`            DATE,
  `date_filed`                        DATE,
  `date_terminated`                   DATE,
  `date_last_filing`                  DATE,
  `case_name_short`                   VARCHAR(500),
  `case_name`                         TEXT,
  `case_name_full`                    MEDIUMTEXT,
  `slug`                              VARCHAR(150),
  `docket_number`                     VARCHAR(750),
  `docket_number_core`                BIGINT(20),
  `pacer_case_id`                     BIGINT(20),
  `cause`                             TEXT,
  `nature_of_suit`                    VARCHAR(1000),
  `jury_demand`                       VARCHAR(255),
  `jurisdiction_type`                 VARCHAR(50),
  `appellate_fee_status`              VARCHAR(40),
  `appellate_case_type_information`   VARCHAR(150),
  `mdl_status`                        VARCHAR(40),
  `filepath_ia`                       VARCHAR(200),
  `filepath_ia_json`                  VARCHAR(200),
  `ia_upload_failure_count`           BIGINT(20),
  `ia_needs_upload`                   char(1),
  `ia_date_first_change`              DATETIME,
  `date_blocked`                      DATE,
  `blocked`                           char(1),
  `appeal_from_id`                    BIGINT(20),
  `tags`                              TEXT,
  `panel`                             TEXT,
  # end
  `data_source_url`     TEXT          NOT NULL,
  `created_by`          VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `docket_id` (`docket_id`),
  INDEX `docket` (`docket_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Dockets from CourtListener.com...., Created by Oleksii Kuts, Task #470';
======================================================
CREATE TABLE `cl_courts`
(
  `id`                  BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  `run_id`              BIGINT(20),
  # begin
  `court_textcode`      VARCHAR(20),
  `court_name`          VARCHAR(255),
  `court_short_name`    VARCHAR(255),
  `state`               VARCHAR(255) DEFAULT NULL,
  `city`                VARCHAR(255) DEFAULT NULL,
  `country`             VARCHAR(255) DEFAULT NULL,
  `court_start_date`    DATE,
  `court_end_date`      DATE,
  `pacer_court_id`      BIGINT(20),
  `link`                VARCHAR(255),
  `court_jurisdiction`  VARCHAR(50),
  # end
  `data_source_url`     TEXT          NOT NULL,
  `created_by`          VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`      BIGINT,
  `deleted`             BOOLEAN                DEFAULT 0,
  `md5_hash`            VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`),
  INDEX `court_textcode` (`court_textcode`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Courts from CourtListener.com...., Created by Oleksii Kuts, Task #470';

CREATE TABLE `cl_raw_courts`
(
  `id`                        BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  # begin
  `resource_uri`              VARCHAR(255)  NOT NULL,
  `court_id`                  VARCHAR(20),
  `pacer_court_id`            BIGINT(20),
  `pacer_has_rss_feed`        VARCHAR(5),
  `pacer_rss_entry_types`     VARCHAR(255),
  `date_last_pacer_contact`   DATETIME,
  `fjc_court_id`              VARCHAR(2),
  `court_date_modified`       DATETIME,
  `court_in_use`              VARCHAR(5),
  `has_opinion_scraper`       VARCHAR(5),
  `has_oral_argument_scraper` VARCHAR(5),
  `court_position`            FLOAT(11,8),
  `court_citation_str`        VARCHAR(50),
  `court_short_name`          VARCHAR(255),
  `court_full_name`           VARCHAR(255),
  `court_url`                 VARCHAR(255),
  `court_start_date`          DATETIME,
  `court_end_date`            DATETIME,
  `court_jurisdiction`        VARCHAR(50),
  # end
  `data_source_url`     TEXT          NOT NULL,
  `created_by`          VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `court_id` (`court_id`),
  INDEX `court` (`court_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Courts from CourtListener.com...., Created by Oleksii Kuts, Task #470';
======================================================
CREATE TABLE `cl_judge_political_affiliation`
(
  `id`                      BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  `run_id`                  BIGINT(20),
  # begin
  `person_id`               INT,
  `political_party`         VARCHAR(50),
  `date_start`              DATE,
  `date_granularity_start`  VARCHAR(10),
  `date_end`                DATE,
  `date_granularity_end`    VARCHAR(10),
  # end
  `data_source_url`         TEXT          NOT NULL,
  `created_by`              VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`              DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`          BIGINT,
  `deleted`                 BOOLEAN                DEFAULT 0,
  `md5_hash`                VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`),
  INDEX `person_id` (`person_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Judges political affiliation from CourtListener.com...., Created by Oleksii Kuts, Task #470';

CREATE TABLE `cl_raw_judge_political_affiliation`
(
  `id`                      BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  # begin
  `resource_uri`            VARCHAR(255)  NOT NULL,
  `affiliation_id`          INT,
  `person_id`               INT,
  `date_created`            DATETIME,
  `date_modified`           DATETIME,
  `political_party`         VARCHAR(50),
  `source`                  VARCHAR(10),
  `date_start`              DATETIME,
  `date_granularity_start`  VARCHAR(10),
  `date_end`                DATETIME,
  `date_granularity_end`    VARCHAR(10),
  # end
  `data_source_url`         TEXT          NOT NULL,
  `created_by`              VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`              DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`              DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `affiliation_id` (`affiliation_id`),
  INDEX `affiliation` (`affiliation_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Judges political affiliation from CourtListener.com...., Created by Oleksii Kuts, Task #470';
====================================================================
CREATE TABLE `cl_schools`
(
  `id`                  BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  `run_id`              BIGINT(20),
  # begin
  `school_id`           INT,
  `is_alias_of_id`      INT,
  `school_name`         VARCHAR(255),
  `school_ein`          BIGINT,
  # end
  `data_source_url`     TEXT          NOT NULL,
  `created_by`          VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`      BIGINT,
  `deleted`             BOOLEAN                DEFAULT 0,
  `md5_hash`            VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`),
  INDEX `school_id` (`school_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Schools from CourtListener.com...., Created by Oleksii Kuts, Task #470';

CREATE TABLE `cl_raw_schools`
(
  `id`                  BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  # begin
  `resource_uri`        VARCHAR(255)  NOT NULL,
  `school_id`           INT,
  `is_alias_of`         VARCHAR(255),
  `date_created`        DATETIME,
  `date_modified`       DATETIME,
  `school_name`         VARCHAR(255),
  `school_ein`          BIGINT,
  # end
  `data_source_url`     TEXT          NOT NULL,
  `created_by`          VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `school_id` (`school_id`),
  INDEX `school` (`school_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Judges from CourtListener.com...., Created by Oleksii Kuts, Task #470';
====================================================================
CREATE TABLE `cl_judge_schools`
(
  `id`                  BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  `run_id`              BIGINT(20),
  # begin
  `person_id`           INT,
  `school_id`           INT,
  `degree_level`        VARCHAR(10),
  `degree_detail`       VARCHAR(150),
  `degree_year`         INT,
  # end
  `data_source_url`     TEXT          NOT NULL,
  `created_by`          VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`      BIGINT,
  `deleted`             BOOLEAN                DEFAULT 0,
  `md5_hash`            VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`),
  INDEX `person_id` (`person_id`),
  INDEX `school_id` (`school_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Judges Education from CourtListener.com...., Created by Oleksii Kuts, Task #470';

CREATE TABLE `cl_raw_judge_schools`
(
  `id`                  BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  # begin
  `resource_uri`        VARCHAR(255)  NOT NULL,
  `education_id`        INT,
  `school_id`           INT,
  `person_id`           INT,
  `date_created`        DATETIME,
  `date_modified`       DATETIME,
  `degree_level`        VARCHAR(10),
  `degree_detail`       VARCHAR(150),
  `degree_year`         INT,
  # end
  `data_source_url`     TEXT          NOT NULL,
  `created_by`          VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `education_id` (`education_id`),
  INDEX `education` (`education_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Judges from CourtListener.com...., Created by Oleksii Kuts, Task #470';
=====================================================================
CREATE TABLE `cl_judge_info`
(
  `id`                    BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  `run_id`              BIGINT(20),
  # begin
  `person_id`             BIGINT(20),
  `is_alias_of_id`        VARCHAR(255),
  `name_slug`             VARCHAR(100),
  `name_first`            VARCHAR(50),
  `name_middle`           VARCHAR(50),
  `name_last`             VARCHAR(50),
  `name_suffix`           VARCHAR(10),
  `gender`                VARCHAR(1),
  `race`                  VARCHAR(20),
  `religion`              VARCHAR(30),
  `date_dob`              DATE,
  `date_granularity_dob`  VARCHAR(10),
  `dob_city`              VARCHAR(100),
  `dob_state`             VARCHAR(2),
  `dob_country`           VARCHAR(100),
  `date_dod`              DATE,
  `date_granularity_dod`  VARCHAR(10),
  `dod_city`              VARCHAR(100),
  `dod_state`             VARCHAR(2),
  `dod_country`           VARCHAR(100),
  `fjc_person_id`         BIGINT(20),
  `ftm_total_received`    FLOAT(11,2),
  `ftm_eid`               BIGINT(20),
  # end
  `data_source_url`       TEXT          NOT NULL,
  `created_by`            VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`            DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`      BIGINT,
  `deleted`             BOOLEAN                DEFAULT 0,
  `md5_hash`            VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`),
  INDEX `person_id` (`person_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Judges from CourtListener.com...., Created by Oleksii Kuts, Task #470';

CREATE TABLE `cl_raw_judge_info`
(
  `id`                    BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  # begin
  `resource_uri`          VARCHAR(255)  NOT NULL,
  `person_id`             BIGINT(20),
  `race`                  VARCHAR(20),
  `is_alias_of`           VARCHAR(255),
  `date_created`          DATETIME,
  `date_modified`         DATETIME,
  `date_completed`        DATETIME,
  `fjc_person_id`         BIGINT(20),
  `name_slug`             VARCHAR(100),
  `name_first`            VARCHAR(50),
  `name_middle`           VARCHAR(50),
  `name_last`             VARCHAR(50),
  `name_suffix`           VARCHAR(10),
  `date_dob`              DATETIME,
  `date_granularity_dob`  VARCHAR(10),
  `date_dod`              DATETIME,
  `date_granularity_dod`  VARCHAR(10),
  `dob_city`              VARCHAR(100),
  `dob_state`             VARCHAR(2),
  `dob_country`           VARCHAR(100),
  `dod_city`              VARCHAR(100),
  `dod_state`             VARCHAR(2),
  `dod_country`           VARCHAR(100),
  `gender`                VARCHAR(1),
  `religion`              VARCHAR(30),
  `ftm_total_received`    FLOAT(11,2),
  `ftm_eid`               BIGINT(20),
  `has_photo`             VARCHAR(5),
  # end
  `data_source_url`       TEXT          NOT NULL,
  `created_by`            VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`            DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `person_id` (`person_id`),
  INDEX `person` (`person_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Judges from CourtListener.com...., Created by Oleksii Kuts, Task #470';
======================================================
CREATE TABLE `cl_judge_job`
(
  `id`                                  BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  `run_id`                              BIGINT(20),
  # begin
  `person_id`                           INT,
  `supervisor_id`                       INT,
  `predecessor_id`                      INT,
  `school_id`                           INT,
  `court_textcode`                      VARCHAR(20),
  `appointer_id`                        INT,
  `position_type`                       VARCHAR(20),
  `job_title`                           VARCHAR(120),
  `sector`                              INT,
  `organization_name`                   VARCHAR(150),
  `location_city`                       VARCHAR(100),
  `location_state`                      VARCHAR(2),
  `date_nominated`                      DATE,
  `date_elected`                        DATE,
  `date_recess_appointment`             DATE,
  `date_referred_to_judicial_committee` DATE,
  `date_judicial_committee_action`      DATE,
  `judicial_committee_action`           VARCHAR(100),
  `date_hearing`                        DATE,
  `date_confirmation`                   DATE,
  `date_start`                          DATE,
  `date_granularity_start`              VARCHAR(10),
  `date_termination`                    DATE,
  `termination_reason`                  VARCHAR(20),
  `date_granularity_termination`        VARCHAR(10),
  `date_retirement`                     DATE,
  `nomination_process`                  VARCHAR(10),
  `vote_type`                           VARCHAR(1),
  `voice_vote`                          VARCHAR(5),
  `votes_yes`                           TINYINT,
  `votes_no`                            TINYINT,
  `votes_yes_percent`                   FLOAT(4,2),
  `votes_no_percent`                    FLOAT(4,2),
  `how_selected`                        VARCHAR(10),
  `has_inferred_values`                 VARCHAR(5),
  # end
  `data_source_url`     TEXT          NOT NULL,
  `created_by`          VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `touched_run_id`      BIGINT,
  `deleted`             BOOLEAN                DEFAULT 0,
  `md5_hash`            VARCHAR(255),
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`),
  INDEX `person_id` (`person_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Judges Jobs from CourtListener.com...., Created by Oleksii Kuts, Task #470';

CREATE TABLE `cl_raw_judge_job`
(
  `id`                                  BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  # begin
  `resource_uri`                        VARCHAR(255)  NOT NULL,
  `job_id`                              INT,
  `retention_events`                    VARCHAR(255),
  `person_id`                           INT,
  `supervisor_id`                       INT,
  `predecessor_id`                      INT,
  `school_id`                           INT,
  `court_id`                            VARCHAR(20),
  `appointer_id`                        INT,
  `date_created`                        DATETIME,
  `date_modified`                       DATETIME,
  `position_type`                       VARCHAR(20),
  `job_title`                           VARCHAR(120),
  `sector`                              INT,
  `organization_name`                   VARCHAR(150),
  `location_city`                       VARCHAR(100),
  `location_state`                      VARCHAR(2),
  `date_nominated`                      DATETIME,
  `date_elected`                        DATETIME,
  `date_recess_appointment`             DATETIME,
  `date_referred_to_judicial_committee` DATETIME,
  `date_judicial_committee_action`      DATETIME,
  `judicial_committee_action`           VARCHAR(100),
  `date_hearing`                        DATETIME,
  `date_confirmation`                   DATETIME,
  `date_start`                          DATETIME,
  `date_granularity_start`              VARCHAR(10),
  `date_termination`                    DATETIME,
  `termination_reason`                  VARCHAR(20),
  `date_granularity_termination`        VARCHAR(10),
  `date_retirement`                     DATETIME,
  `nomination_process`                  VARCHAR(10),
  `vote_type`                           VARCHAR(1),
  `voice_vote`                          VARCHAR(5),
  `votes_yes`                           TINYINT,
  `votes_no`                            TINYINT,
  `votes_yes_percent`                   FLOAT(4,2),
  `votes_no_percent`                    FLOAT(4,2),
  `how_selected`                        VARCHAR(10),
  `has_inferred_values`                 VARCHAR(5),
  # end
  `data_source_url`     TEXT          NOT NULL,
  `created_by`          VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `job_id` (`job_id`),
  INDEX `job` (`job_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Judges from CourtListener.com...., Created by Oleksii Kuts, Task #470';

======================================================
CREATE TABLE `cl_opinions`
(
  `id`                  BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  # begin
  `opinion_id`          INT,
  `absolute_url`        VARCHAR(255),
  `claster_id`          INT,
  `author_id`           INT,
  `joined_by`           VARCHAR(255),
  `date_created`        DATETIME,
  `date_modified`       DATETIME,
  `author_str`          VARCHAR(255),
  `per_curiam`          VARCHAR(5),
  `joined_by_str`       VARCHAR(255),
  `type`                VARCHAR(50),
  `sha1`                VARCHAR(40),
  `page_count`          INT,
  `download_url`        VARCHAR(255),
  `local_path`          VARCHAR(255),
  `plain_text`          LONGTEXT,
  `html`                LONGTEXT,
  `html_lawbox`         LONGTEXT,
  `html_columbia`       LONGTEXT,
  `html_anon_2020`      LONGTEXT,
  `xml_harvard`         LONGTEXT,
  `html_with_citations` LONGTEXT,
  `extracted_by_ocr`    VARCHAR(5),
  `opinions_cited`      TEXT,
  # end
  `data_source_url`     VARCHAR(255)  NOT NULL,
  `created_by`          VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`             BOOLEAN                DEFAULT 0,
  UNIQUE KEY `opinion_modified_id` (`opinion_id`, `date_modified`),
  INDEX `opinion` (`opinion_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Opinions from CourtListener.com...., Created by Oleksii Kuts, Task #470';

INSERT INTO `cl_opinions`
(SELECT
  null,
  id,
  null,
  cluster_id,
  author_id,
  null,
  date_created,
  date_modified,
  author_str,
  per_curiam,
  joined_by_str,
  type,
  sha1,
  page_count,
  download_url,
  local_path,
  plain_text,
  html,
  html_lawbox,
  html_columbia,
  html_anon_2020,
  xml_harvard,
  html_with_citations,
  extracted_by_ocr,
  null,
  'cl_csv_opinions, bulk data from https://com-courtlistener-storage.s3-us-west-2.amazonaws.com/list.html?prefix=bulk-data/',
  'Oleksii Kuts',
  current_timestamp(),
  current_timestamp(),
  0 as deleted
FROM `cl_csv_opinions` where sha1 != '' order by id desc limit 1);

CREATE TABLE `cl_raw_opinions`
(
  # begin
  `opinion_id`          INT,
  `absolute_url`        VARCHAR(255),
  `claster_id`          INT,
  `author_id`           INT,
  `joined_by`           VARCHAR(255),
  `date_created`        DATETIME,
  `date_modified`       DATETIME,
  `author_str`          VARCHAR(255),
  `per_curiam`          VARCHAR(5),
  `joined_by_str`       VARCHAR(255),
  `type`                VARCHAR(50),
  `sha1`                VARCHAR(40),
  `page_count`          INT,
  `download_url`        VARCHAR(255),
  `local_path`          VARCHAR(255),
  `plain_text`          LONGTEXT,
  `html`                LONGTEXT,
  `html_lawbox`         LONGTEXT,
  `html_columbia`       LONGTEXT,
  `html_anon_2020`      LONGTEXT,
  `xml_harvard`         LONGTEXT,
  `html_with_citations` LONGTEXT,
  `extracted_by_ocr`    VARCHAR(5),
  `opinions_cited`      TEXT,
  # end
  `data_source_url`     VARCHAR(255)  NOT NULL,
  `created_by`          VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `opinion_id` (`opinion_id`),
  INDEX `opinion` (`opinion_id`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Opinions from CourtListener.com...., Created by Oleksii Kuts, Task #470';

======================================================
select length(appeal_from_str) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(assigned_to_str) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(referred_to_str) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(panel_str) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(case_name_short) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(case_name) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(case_name_full) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(slug) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(docket_number) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(cause) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(nature_of_suit) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(jury_demand) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(jurisdiction_type) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(appellate_fee_status) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(appellate_case_type_information) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(mdl_status) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(filepath_ia) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(filepath_ia_json) as l1 from cl_csv_dockets order by l1 desc limit 2;
select length(court_id) as l1 from cl_csv_dockets order by l1 desc limit 2;


CREATE TABLE `cl_csv_dockets`
(
  `id`                               INT,
  `date_created`                     DATETIME,
  `date_modified`                    DATETIME,
  `source`                           INT,
  `appeal_from_str`                  VARCHAR(200),
  `assigned_to_str`                  VARCHAR(100),
  `referred_to_str`                  TEXT,
  `panel_str`                        VARCHAR(100),
  `date_cert_granted`                DATE,
  `date_cert_denied`                 DATE,
  `date_argued`                      DATE,
  `date_reargued`                    DATE,
  `date_reargument_denied`           DATE,
  `date_filed`                       DATE,
  `date_terminated`                  DATE,
  `date_last_filing`                 DATE,
  `case_name_short`                  VARCHAR(500),
  `case_name`                        TEXT,
  `case_name_full`                   MEDIUMTEXT,
  `slug`                             VARCHAR(150),
  `docket_number`                    VARCHAR(750),
  `docket_number_core`               INT,
  `pacer_case_id`                    INT,
  `cause`                            TEXT,
  `nature_of_suit`                   VARCHAR(1000),
  `jury_demand`                      VARCHAR(255),
  `jurisdiction_type`                VARCHAR(50),
  `appellate_fee_status`             VARCHAR(40),
  `appellate_case_type_information`  VARCHAR(150),
  `mdl_status`                       VARCHAR(40),
  `filepath_ia`                      VARCHAR(200),
  `filepath_ia_json`                 VARCHAR(200),
  `date_blocked`                     DATE,
  `blocked`                          CHAR(1),
  `appeal_from_id`                   INT,
  `assigned_to_id`                   INT,
  `court_id`                         VARCHAR(30),
  `idb_data_id`                      INT,
  `originating_court_information_id` INT,
  `referred_to_id`                   INT
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Dockets from bulk data from CourtListener.com...., Created by Oleksii Kuts, Task #470';

LOAD DATA LOCAL INFILE '/media/developer/dockets-2022-08-02.csv'
    INTO TABLE `cl_csv_dockets`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES;

======================================================
select length(judges) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(slug) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(case_name_short) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(case_name) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(case_name_full) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(scdb_id) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(source) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(procedural_history) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(attorneys) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(nature_of_suit) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(posture) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(syllabus) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(headnotes) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(summary) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(disposition) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(history) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(other_dates) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(cross_reference) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(correction) as l1 from cl_csv_clusters order by l1 desc limit 2;
select length(precedential_status) as l1 from cl_csv_clusters order by l1 desc limit 2;

CREATE TABLE `cl_csv_clusters`
(
  `id`                        INT,
  `date_created`              DATETIME,
  `date_modified`             DATETIME,
  `judges`                    TEXT,
  `date_filed`                DATE,
  `date_filed_is_approximate` CHAR(1),
  `slug`                      VARCHAR(255),
  `case_name_short`           VARCHAR(3000),
  `case_name`                 TEXT,
  `case_name_full`            MEDIUMTEXT,
  `scdb_id`                   VARCHAR(255),
  `scdb_decision_direction`   INT,
  `scdb_votes_majority`       INT,
  `scdb_votes_minority`       INT,
  `source`                    VARCHAR(10),
  `procedural_history`        VARCHAR(25),
  `attorneys`                 MEDIUMTEXT,
  `nature_of_suit`            TEXT,
  `posture`                   MEDIUMTEXT,
  `syllabus`                  TEXT,
  `headnotes`                 TEXT,
  `summary`                   MEDIUMTEXT,
  `disposition`               TEXT,
  `history`                   TEXT,
  `other_dates`               VARCHAR(1500),
  `cross_reference`           VARCHAR(1500),
  `correction`                TEXT,
  `citation_count`            INT,
  `precedential_status`       VARCHAR(255),
  `date_blocked`              DATE,
  `blocked`                   CHAR(1),
  `docket_id`                 INT
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Clusters from bulk data from CourtListener.com...., Created by Oleksii Kuts, Task #470';

LOAD DATA LOCAL INFILE '/media/developer/opinion-clusters-2022-08-02.csv'
    INTO TABLE `cl_csv_clusters`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES;
======================================================
select length(author_str) as l1 from cl_csv_opinions order by l1 desc limit 2;
select length(joined_by_str) as l1 from cl_csv_opinions order by l1 desc limit 2;
select length(type) as l1 from cl_csv_opinions order by l1 desc limit 2;
select length(sha1) as l1 from cl_csv_opinions order by l1 desc limit 2;
select length(download_url) as l1 from cl_csv_opinions order by l1 desc limit 2;
select length(local_path) as l1 from cl_csv_opinions order by l1 desc limit 2;
select length(plain_text) as l1 from cl_csv_opinions order by l1 desc limit 2;
select length(html) as l1 from cl_csv_opinions order by l1 desc limit 2;
select length(html_lawbox) as l1 from cl_csv_opinions order by l1 desc limit 2;
select length(html_columbia) as l1 from cl_csv_opinions order by l1 desc limit 2;
select length(html_anon_2020) as l1 from cl_csv_opinions order by l1 desc limit 2;
select length(xml_harvard) as l1 from cl_csv_opinions order by l1 desc limit 2;
select length(html_with_citations) as l1 from cl_csv_opinions order by l1 desc limit 2;

CREATE TABLE `cl_csv_opinions`
(
  `id`                  INT NOT NULL,
  `date_created`        DATETIME NOT NULL,
  `date_modified`       DATETIME NOT NULL,
  `author_str`          VARCHAR(255) NOT NULL,
  `per_curiam`          CHAR(1) NOT NULL,
  `joined_by_str`       MEDIUMTEXT NOT NULL,
  `type`                VARCHAR(255) NOT NULL,
  `sha1`                VARCHAR(40) NOT NULL,
  `page_count`          INT,
  `download_url`        VARCHAR(255),
  `local_path`          VARCHAR(255) NOT NULL,
  `plain_text`          MEDIUMTEXT NOT NULL,
  `html`                MEDIUMTEXT NOT NULL,
  `html_lawbox`         MEDIUMTEXT NOT NULL,
  `html_columbia`       MEDIUMTEXT NOT NULL,
  `html_anon_2020`      MEDIUMTEXT NOT NULL,
  `xml_harvard`         MEDIUMTEXT NOT NULL,
  `html_with_citations` MEDIUMTEXT NOT NULL,
  `extracted_by_ocr`    CHAR(1) NOT NULL,
  `author_id`           INT,
  `cluster_id`          INT NOT NULL
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Opinions from bulk data from CourtListener.com...., Created by Oleksii Kuts, Task #470';

LOAD DATA LOCAL INFILE '/media/developer/opinions-2022-08-02.csv'
    INTO TABLE `cl_csv_opinions`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '/media/developer/opinions_0.csv'
    INTO TABLE `cl_csv_opinions`
    FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES;
