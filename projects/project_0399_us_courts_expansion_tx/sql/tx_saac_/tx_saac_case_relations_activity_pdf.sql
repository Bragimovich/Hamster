create table tx_saac_case_relations_activity_pdf
(
    case_activities_md5            VARCHAR(255) DEFAULT NULL,
    case_pdf_on_aws_md5            VARCHAR(255) DEFAULT NULL,
) DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_520_ci;
