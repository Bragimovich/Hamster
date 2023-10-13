create table ct_saac_case_party
(
  court_id                      BIGINT AUTO_INCREMENT PRIMARY KEY,
  case_id                       VARCHAR(255),
  is_lawyer                     VARCHAR(255),
  party_name                    VARCHAR(255),
  party_type                    VARCHAR(255),
  party_law_firm                VARCHAR(255),
  party_address                 VARCHAR(255),
  party_city                    VARCHAR(255),
  party_state                   VARCHAR(255),
  party_zip                     VARCHAR(255),
  party_description             TEXT,

  data_source_url               VARCHAR(255),
  created_by                    VARCHAR(255)       DEFAULT 'Dmitry Suschinsky',
  created_at                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  md5_hash                      VARCHAR(255)
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;