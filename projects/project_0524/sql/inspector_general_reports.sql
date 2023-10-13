CREATE TABLE inspector_general_reports
(
  id              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  title text,
  report_date  date,
  agency_reviewed  varchar(255),
  report_number  varchar(255),
  report_pdf_link text,
  aws_report_pdf   varchar(255),
  additional_details_link  varchar(255),
  aws_additional_details   varchar(255),
  questioned_costs  varchar(255),
  funds_for_better_use  varchar(255),
  number_of_recommendations  int,
  report_description  text,
  type varchar(255),
  data_source_url TEXT,
  created_by      VARCHAR(255)      DEFAULT 'Abdur Rehman',
  created_at      DATETIME          DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  run_id          BIGINT(20),
  touched_run_id  BIGINT,
  deleted         BOOLEAN           DEFAULT 0,
  md5_hash        VARCHAR(255),
  UNIQUE KEY md5 (md5_hash),
  INDEX run_id (run_id),
  INDEX touched_run_id (touched_run_id),
  INDEX deleted (deleted)
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;