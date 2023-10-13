CREATE TABLE `pa_sc_case_relations_info_pdf`
(
  `id`                  BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `case_info_md5`       VARCHAR(32) DEFAULT NULL,
  `case_pdf_on_aws_md5` VARCHAR(32) DEFAULT NULL,
  UNIQUE KEY `md5_info_aws` (`case_info_md5`, `case_pdf_on_aws_md5`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
