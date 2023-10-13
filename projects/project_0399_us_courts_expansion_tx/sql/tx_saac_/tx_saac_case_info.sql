create table tx_saac_case_info
(
  id                            BIGINT(20) auto_increment   primary key,
  court_id                      BIGINT,
  case_id                       VARCHAR(64)  DEFAULT NULL,
  case_name                     TEXT DEFAULT NULL,
  case_filed_date               VARCHAR(64)  DEFAULT NULL,
  case_type                     VARCHAR(64)  DEFAULT NULL,
  case_description              VARCHAR(255) DEFAULT NULL,
  disposition_or_status         VARCHAR(64)  DEFAULT NULL,
  status_as_of_date             VARCHAR(64)  DEFAULT NULL,
  judge_name                    VARCHAR(255) DEFAULT NULL,
  lower_court_id                VARCHAR(255) DEFAULT NULL,
  lower_case_id                 VARCHAR(255) DEFAULT NULL,

  data_source_url               VARCHAR(255) DEFAULT NULL,
  created_by                    VARCHAR(64)        DEFAULT 'Dmitry Suschinsky',
  created_at                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  scrape_frequency              VARCHAR(10)  default 'weekly' null,

  touched_run_id                BIGINT,
  deleted                       BOOLEAN DEFAULT 0,
  md5_hash                      VARCHAR(255),
  run_id                        BIGINT(20)

) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;
