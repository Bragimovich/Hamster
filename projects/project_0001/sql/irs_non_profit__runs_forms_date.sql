CREATE TABLE irs_non_profit__runs_forms_date
(
    `id`                    BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
    form_type               varchar(255) DEFAULT NULL,
    last_data_source_update DATE         DEFAULT NULL,
    run_id                  BIGINT(20)   DEFAULT NULL,
    `created_at`            DATETIME     DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;