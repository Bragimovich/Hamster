create table us_case_status_distinct
(
  `id`                  BIGINT(20) auto_increment   primary key,
  court_id              BIGINT(20) NOT NULL,
  phase            int(7) default 1,
   status              varchar(511),
   clean_status        varchar(511),
   similar_to           bigint(20) default 0 not null,
   matched           boolean default 0,
   count            int,

  `created_by`          VARCHAR(255)       DEFAULT 'Maxim G',
  `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX court_id (court_id),
  INDEX phase_court (phase),
  INDEX matched (matched),
  INDEX similar_to (similar_to)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci
Comment = 'distinct statuses from us_courts tables';



create table us_case_status_normalized
(
    id                 BIGINT(20) auto_increment   primary key,
    normalized_status        varchar(511),

    `created_by`          VARCHAR(255)       DEFAULT 'Maxim G',
    `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    Comment = 'Set of cleaned and normalized statuses from us_case_status_distinct table'


create table us_case_status_distinct_to_normalized
(
    id                 BIGINT(20) auto_increment   primary key,
    status_id          BIGINT(20) NOT NULL,
    normalized_status_id BIGINT(20) NOT NULL,

    `created_by`          VARCHAR(255)       DEFAULT 'Maxim G',
    `created_at`          DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX status_id (status_id),
    INDEX normalized_status_id (normalized_status_id)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    Comment = 'Mapping of distinct statuses to normalized statuses'

