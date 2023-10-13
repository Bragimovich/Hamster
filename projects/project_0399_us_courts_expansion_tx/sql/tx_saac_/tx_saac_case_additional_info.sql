create table tx_saac_case_additional_info
(
  id                            BIGINT(20) auto_increment   primary key,
  court_id                      BIGINT,
  case_id                       VARCHAR(64)  DEFAULT NULL,
  lower_court_name              VARCHAR(128) DEFAULT NULL,
  lower_case_id                 VARCHAR(64)  DEFAULT NULL,
  lower_judge_name              VARCHAR(255) DEFAULT NULL,
  lower_judgement_date          DATE DEFAULT NULL,
  lower_link                    VARCHAR(64)  DEFAULT NULL,
  disposition                   VARCHAR(64)  DEFAULT NULL,

  data_source_url               VARCHAR(255) DEFAULT NULL,
  created_by                    VARCHAR(255)       DEFAULT 'Dmitry Suschinsky',
  created_at                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  scrape_frequency              VARCHAR(10)  default 'weekly' null,
  updated_at                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  touched_run_id                BIGINT,
  deleted                       BOOLEAN DEFAULT 0,
  md5_hash                      VARCHAR(255),
  run_id                        BIGINT(20)

) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;
