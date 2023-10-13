CREATE TABLE us_court_cases.de_case_relations_activity_pdf
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `court_id`              int                                  null,
  `case_id`               varchar(255)                         not null,

  `case_activities_md5`             varchar(255)                       null,
  `case_pdf_on_aws_md5`                varchar(255)                       null
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
