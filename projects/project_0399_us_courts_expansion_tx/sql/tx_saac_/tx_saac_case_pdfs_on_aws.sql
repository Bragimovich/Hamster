create table tx_saac_case_pdfs_on_aws
(
  id                            BIGINT(20) auto_increment   primary key,
  court_id                      BIGINT,
  case_id                       VARCHAR(64)        DEFAULT NULL,
  source_type                   VARCHAR(255)       DEFAULT NULL,
  aws_link                      VARCHAR(255)       DEFAULT NULL,
  source_link                   VARCHAR(64)        DEFAULT NULL,

  data_source_url               VARCHAR(255)        DEFAULT NULL,
  created_by                    VARCHAR(255)       DEFAULT 'Dmitry Suschinsky',
  created_at                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  scrape_frequency              VARCHAR(10)  default 'weekly' null,

  touched_run_id                BIGINT,
  deleted                       BOOLEAN DEFAULT 0,
  md5_hash                      VARCHAR(255),
  run_id                        BIGINT(20)
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;
