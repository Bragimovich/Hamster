create table ct_saac_case_activities
(
  court_id                      BIGINT AUTO_INCREMENT PRIMARY KEY,
  case_id                       VARCHAR(255),
  activity_date                 DATE,
  activity_desc                 MEDIUM_TEXT,
  activity_type                 VARCHAR(255),
  file                          VARCHAR(255),

  data_source_url               VARCHAR(255),
  created_by                    VARCHAR(255)       DEFAULT 'Dmitry Suschinsky',
  created_at                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  md5_hash                      VARCHAR(255)
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;
