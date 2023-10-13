CREATE TABLE ia_sc_case_party
(
  id                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  run_id            BIGINT(20),
  court_id          int,

  case_id           VARCHAR(100),
  is_lawyer         BOOLEAN,
  party_name        VARCHAR(255),
  party_type        VARCHAR(255),
  party_law_firm    VARCHAR(255),
  party_address     VARCHAR(255),
  party_city        VARCHAR(255),
  party_state       VARCHAR(255),
  party_zip         VARCHAR(255),
  party_description VARCHAR(255),

  data_source_url   VARCHAR(255)      DEFAULT 'https://www.iowacourts.gov',
  created_by        VARCHAR(100)      DEFAULT 'Robert Arnold',
  created_at        DATETIME          DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  touched_run_id    BIGINT,
  deleted           BOOLEAN           DEFAULT 0,
  md5_hash          VARCHAR(255),
  UNIQUE KEY md5 (md5_hash),
  INDEX run_id (run_id),
  INDEX touched_run_id (touched_run_id),
  INDEX deleted (deleted),
  KEY id (id)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Table for table from task 555. Made by Robert A.';