create table `ut_saac_case_unfetched_pdfs`
(
  `id`                   int auto_increment   primary key,
  `data_source_url`      VARCHAR (255),
  `created_by`           VARCHAR(255)       DEFAULT 'Raza',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `status_idx` (`status`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
