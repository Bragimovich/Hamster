create table ct_saac_case_additional_info
(
  court_id                      BIGINT AUTO_INCREMENT PRIMARY KEY,
  case_id                       VARCHAR(255),
  lower_court_name              VARCHAR(255),
  lower_case_id                 VARCHAR(255),
  lower_judge_name              VARCHAR(255),
  lower_judgement_date          DATE,
  lower_link                    VARCHAR(255),
  disposition                   VARCHAR(255),

  data_source_url               VARCHAR(255),
  created_by                    VARCHAR(255)       DEFAULT 'Dmitry Suschinsky',
  created_at                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  md5_hash                      VARCHAR(255)

) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;
