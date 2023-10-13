create table tx_saac_case_party
(
  id                            BIGINT(20) auto_increment   primary key,
  court_id                      BIGINT,
  case_id                       VARCHAR(64)  DEFAULT NULL,
  is_lawyer                     VARCHAR(64)  DEFAULT NULL,
  party_name                    VARCHAR(255) DEFAULT NULL,
  party_type                    VARCHAR(255) DEFAULT NULL,
  party_law_firm                VARCHAR(255) DEFAULT NULL,
  party_address                 VARCHAR(255) DEFAULT NULL,
  party_city                    VARCHAR(255) DEFAULT NULL,
  party_state                   VARCHAR(64)  DEFAULT NULL,
  party_zip                     VARCHAR(64)  DEFAULT NULL,
  party_description             TEXT DEFAULT NULL,

  data_source_url               VARCHAR(255) DEFAULT NULL,
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