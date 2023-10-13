CREATE TABLE us_court_cases.fl_saac_case_relations_activity_pdf
(
  id              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  case_activities_md5             varchar(255)                       null,
  case_pdf_on_aws_md5                varchar(255)                       null,
  created_at          datetime     default CURRENT_TIMESTAMP null,
  updated_at          timestamp    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
  UNIQUE KEY (case_activities_md5, case_pdf_on_aws_md5)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by Maxim G for scrape task 543';
