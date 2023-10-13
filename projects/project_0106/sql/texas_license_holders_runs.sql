CREATE TABLE `texas_license_holders_runs`
(
  `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                  BIGINT(20),
  `status`                  varchar(255) default 'processing',
  `licence_type_run`        varchar(255) default 'Appraisers',
  `page_run`                INT          default 1,

  `data_source_url`    VARCHAR(250) default 'https://www.trec.texas.gov/apps/license-holder-search/index.php?lic_name=&lic_hp=&industry=Real+Estate',
  `created_by`      VARCHAR(255)       DEFAULT 'Maxim G',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
