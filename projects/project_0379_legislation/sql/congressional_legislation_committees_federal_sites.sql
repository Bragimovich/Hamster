CREATE TABLE `congressional_legislation_committees_federal_sites`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

  `committee_name`         VARCHAR(511),
  `source_committee`        VARCHAR(255),
  `project_id`              bigint(20),
  `project_name`             VARCHAR(255),

  UNIQUE KEY `committee_name` (`committee_name`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
