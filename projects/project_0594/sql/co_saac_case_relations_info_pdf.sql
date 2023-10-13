CREATE TABLE co_saac_case_relations_info_pdf
(
  id                BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  run_id            BIGINT(20),

  case_info_md5        VARCHAR(255),
  case_pdf_on_aws_md5  VARCHAR(255),

  data_source_url   VARCHAR(255)      DEFAULT 'https://www.courts.state.co.us/Courts/Court_Of_Appeals/Case_Announcements/Index.cfm',
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
  COMMENT = 'Table for table from task 594. Made by Robert A.';
