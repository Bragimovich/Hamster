CREATE TABLE us_court_cases.ne_saac_case_runs
(
  id                    BIGINT AUTO_INCREMENT PRIMARY KEY,
  status                varchar(255) default 'processing'        null,
  created_by            VARCHAR(20) DEFAULT 'William Devries'    NOT NULL,
  created_at            DATETIME    DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at            TIMESTAMP   DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
  INDEX `status` (status)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'ne_saac_case_runs for US Courts Expansion: Nebraska Supreme and Appellate courts (328 and 445), Created by William Devries, Task #558';

CREATE TABLE us_court_cases.ne_saac_case_info
(
  id                    BIGINT AUTO_INCREMENT PRIMARY KEY,
  court_id              SMALLINT                              NOT NULL,
  case_id               VARCHAR(100)                          NULL,
  # begin
  case_name             VARCHAR(1500)                         NULL,
  case_filed_date       DATETIME                              NULL,
  case_type             VARCHAR(2000)                         NULL,
  case_description      VARCHAR(6000)                         NULL,
  disposition_or_status VARCHAR(100)                          NULL,
  status_as_of_date     VARCHAR(255)                          NULL,
  judge_name            VARCHAR(255)                          NULL,
  lower_court_id        SMALLINT                              NULL,
  lower_case_id         VARCHAR(1000)                         NULL,
  # end
  md5_hash              VARCHAR(32)                           NOT NULL,
  created_by            VARCHAR(20) DEFAULT 'William Devries'    NOT NULL,
  created_at            DATETIME    DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at            TIMESTAMP   DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
  data_source_url       VARCHAR(255)                          NULL,
  run_id                BIGINT                                NULL,
  touched_run_id        BIGINT                                NULL,
  deleted               TINYINT(1)  DEFAULT 0                 NULL,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `case_id` (`case_id`),
  INDEX `court_id` (`court_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'ne_saac_case_info for  Created by William Devries, Task #558';

CREATE TABLE us_court_cases.ne_saac_case_party
(
  id                BIGINT AUTO_INCREMENT PRIMARY KEY,
  court_id          SMALLINT                              NOT NULL,
  case_id           VARCHAR(100)                          NULL,
  # begin
  is_lawyer         INT                                   NULL,
  party_name        VARCHAR(255)                          NULL,
  party_type        VARCHAR(255)                          NULL,
  party_law_firm    VARCHAR(1023)                         NULL,
  party_address     VARCHAR(500)                          NULL,
  party_city        VARCHAR(255)                          NULL,
  party_state       VARCHAR(255)                          NULL,
  party_zip         VARCHAR(255)                          NULL,
  party_description TEXT                                  NULL,
  # end
  md5_hash          VARCHAR(32)                           NOT NULL,
  created_by        VARCHAR(20) DEFAULT 'William Devries'    NOT NULL,
  created_at        DATETIME    DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at        TIMESTAMP   DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
  data_source_url   VARCHAR(255)                          NULL,
  run_id            BIGINT                                NULL,
  touched_run_id    BIGINT                                NULL,
  deleted           TINYINT(1)  DEFAULT 0                 NULL,
  UNIQUE KEY `md5` (`md5_hash`),
  INDEX `case_id` (`case_id`),
  INDEX `court_id` (`court_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'ne_saac_case_party for  Created by William Devries, Task #558';

CREATE TABLE us_court_cases.ne_saac_case_activities
(
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  court_id        SMALLINT                              NOT NULL,
  case_id         VARCHAR(100)                          NULL,
  # begin
  activity_date   DATE                                  NULL,
  activity_desc   TEXT                                  NULL,
  activity_type   VARCHAR(1023)                         NULL,
  file            TEXT                                  NULL,
  # end
  md5_hash        VARCHAR(32)                           NOT NULL,
  created_by      VARCHAR(20) DEFAULT 'William Devries'    NOT NULL,
  created_at      DATETIME    DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at      TIMESTAMP   DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
  data_source_url VARCHAR(255)                          NULL,
  run_id          BIGINT                                NULL,
  touched_run_id  BIGINT                                NULL,
  deleted         TINYINT(1)  DEFAULT 0                 NULL,
  UNIQUE KEY `md5`  (`md5_hash`),
  INDEX `case_id`   (`case_id`),
  INDEX `court_id`  (`court_id`),
  INDEX `deleted`   (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'ne_saac_case_activities for `US Courts Expansion: Nebraska Supreme and Appellate courts (328 and 445)`...., Created by William Devries, Task #558';

CREATE TABLE us_court_cases.ne_saac_case_pdfs_on_aws
(
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  court_id        SMALLINT                              NOT NULL,
  case_id         VARCHAR(100)                          NULL,
  # begin
  source_type     VARCHAR(255)                          NULL,
  aws_link        VARCHAR(255)                          NULL,
  source_link     VARCHAR(255)                          NULL,
  aws_html_link   VARCHAR(255)                          NULL,
  # end
  md5_hash        VARCHAR(32)                           NOT NULL,
  created_by      VARCHAR(20) DEFAULT 'William Devries'       NOT NULL,
  created_at      DATETIME    DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at      TIMESTAMP   DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
  data_source_url VARCHAR(255)                          NULL,
  run_id          BIGINT                                NULL,
  touched_run_id  BIGINT                                NULL,
  deleted         TINYINT(1)  DEFAULT 0                 NULL,
  UNIQUE KEY `md5`  (`md5_hash`),
  INDEX `case_id`   (`case_id`),
  INDEX `court_id`  (`court_id`),
  INDEX `deleted`   (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'ne_saac_case_pdfs_on_aws for `US Courts Expansion: Nebraska Supreme and Appellate courts (328 and 445)` ...., Created by William Devries, Task #558';

CREATE TABLE us_court_cases.ne_saac_case_relations_activity_pdf
(
  id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
  court_id            SMALLINT                              NOT NULL,
  case_id             VARCHAR(100)                          NULL,
  # begin
  case_activities_md5 VARCHAR(255)                          NULL,
  case_pdf_on_aws_md5 VARCHAR(255)                          NULL,
  # end
  created_by          VARCHAR(20) DEFAULT 'William Devries' NOT NULL,
  created_at          DATETIME    DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at          TIMESTAMP   DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,

  run_id              BIGINT                                      null,
  touched_run_id      BIGINT                                      null,
  deleted             TINYINT(1)                default 0         null,
  md5_hash            VARCHAR(255)                                null,  
  UNIQUE KEY `unique_data` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'ne_saac_case_relations_activity_pdf for `US Courts Expansion: Nebraska Supreme and Appellate courts (328 and 445)`...., Created by William Devries, Task #558';

CREATE TABLE us_court_cases.ne_saac_case_additional_info
(
  id                    BIGINT AUTO_INCREMENT PRIMARY KEY,
  court_id              SMALLINT                              NOT NULL,
  case_id               VARCHAR(100)                          NULL,
  # begin
  lower_court_name      VARCHAR(255)                          DEFAULT NULL,
  lower_case_id         VARCHAR(255)                          DEFAULT NULL,
  lower_judge_name      TEXT                                  DEFAULT NULL,
  lower_judgement_date  DATE                                  DEFAULT NULL,
  lower_link            VARCHAR(255)                          DEFAULT NULL,
  disposition           VARCHAR(255)                          DEFAULT NULL,
  # end
  md5_hash              VARCHAR(32)                           NOT NULL,
  created_by            VARCHAR(20) DEFAULT 'William Devries'    NOT NULL,
  created_at            DATETIME    DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at            TIMESTAMP   DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
  data_source_url       VARCHAR(255)                          NULL,
  run_id                BIGINT                                NULL,
  touched_run_id        BIGINT                                NULL,
  deleted               TINYINT(1)  DEFAULT 0                 NULL,
  UNIQUE KEY `md5`  (`md5_hash`),
  INDEX `case_id`   (`case_id`),
  INDEX `court_id`  (`court_id`),
  INDEX `deleted`   (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'ne_saac_case_additional_info for `US Courts Expansion: Nebraska Supreme and Appellate courts (328 and 445)`...., Created by William Devries, Task #558';

