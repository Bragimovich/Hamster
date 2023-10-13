CREATE SCHEMA IF NOT EXISTS `public_employees_salaries_staging` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `public_employees_salaries_staging`.`address_employee_association_types`
(
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY,
    `type`            VARCHAR(255) NULL,
    `data_source_url` varchar(255) null,
    `created_by`      varchar(255)          default 'Alim L.',
    `created_at`      DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `public_employees_salaries_staging`.`addresses`
(
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY,
    `city`            VARCHAR(255) NULL,
    `state`           VARCHAR(255) NULL,
    `zip`             VARCHAR(255) NULL,
    `unit`            VARCHAR(255) NULL,
    `data_source_url` varchar(255) null,
    `created_by`      varchar(255)          default 'Alim L.',
    `created_at`      DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `public_employees_salaries_staging`.`compensation_types`
(
    `id`                BIGINT AUTO_INCREMENT PRIMARY KEY,
    `compensation_type` VARCHAR(255) NULL,
    `data_source_url`   varchar(255) null,
    `created_by`        varchar(255)          default 'Alim L.',
    `created_at`        DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `public_employees_salaries_staging`.`agency_types`
(
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY,
    `type`            VARCHAR(255) NULL,
    `data_source_url` varchar(255) null,
    `created_by`      varchar(255)          default 'Alim L.',
    `created_at`      DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `public_employees_salaries_staging`.`employees`
(
    `id`                     BIGINT AUTO_INCREMENT PRIMARY KEY,
    `full_name`              VARCHAR(255) NULL,
    `first_name`             VARCHAR(255) NULL,
    `middle_name`            VARCHAR(255) NULL,
    `last_name`              VARCHAR(255) NULL,
    `suffix`                 VARCHAR(255) NULL,
    `race`                   VARCHAR(255) NULL,
    `gender`                 VARCHAR(255) NULL,
    `birthdate_month`        INT          NULL,
    `birthdate_day_of_month` INT          NULL,
    `birthdate_year`         INT          NULL,
    `full_birthdate`         DATE         NULL,
    `data_source_url`        varchar(255) null,
    `created_by`             varchar(255)          default 'Alim L.',
    `created_at`             DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`             TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `public_employees_salaries_staging`.`agency_location_types`
(
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY,
    `type`            VARCHAR(255) NULL,
    `data_source_url` varchar(255) null,
    `created_by`      varchar(255)          default 'Alim L.',
    `created_at`      DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `public_employees_salaries_staging`.`job_titles`
(
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY,
    `job_title`       VARCHAR(255) NULL,
    `data_source_url` varchar(255) null,
    `created_by`      varchar(255)          default 'Alim L.',
    `created_at`      DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `public_employees_salaries_staging`.`raw_datasets`
(
    `id`                   BIGINT AUTO_INCREMENT PRIMARY KEY,
    `raw_dataset_location` VARCHAR(255) NULL,
    `raw_dataset_prefix`   VARCHAR(255) NULL,
    `data_source_name`     VARCHAR(255) NULL,
    `data_gather_method`   VARCHAR(255) NULL,
    `data_source_url`      varchar(255) null,
    `created_by`           varchar(255)          default 'Alim L.',
    `created_at`           DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `public_employees_salaries_staging`.`raw_dataset_tables`
(
    `id`             BIGINT AUTO_INCREMENT PRIMARY KEY,
    `table_name`     VARCHAR(255) NULL,
    `raw_dataset_id` INT          NOT NULL,
    `created_by`     varchar(255)          default 'Alim L.',
    `created_at`     DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `public_employees_salaries_staging`.`employees_to_addresses`
(
    `id`                                   BIGINT AUTO_INCREMENT PRIMARY KEY,
    `employee_id`                          INT          NULL,
    `address_id`                           INT          NULL,
    `address_employee_association_type_id` INT          NULL,
    `start_month`                          INT          NULL,
    `start_day_of_month`                   INT          NULL,
    `start_year`                           INT          NULL,
    `end_month`                            INT          NULL,
    `end_day_of_month`                     INT          NULL,
    `end_year`                             INT          NULL,
    `isolated_known_date`                  VARCHAR(255) NULL,
    `data_source_url`                      varchar(255) null,
    `created_by`                           varchar(255)          default 'Alim L.',
    `created_at`                           DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                           TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `public_employees_salaries_staging`.`employees_to_locations`
(
    `id`                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    `employee_id`         INT          NULL,
    `location_id`         INT          NULL,
    `start_month`         INT          NULL,
    `start_day_of_month`  INT          NULL,
    `start_year`          INT          NULL,
    `end_month`           INT          NULL,
    `end_day_of_month`    INT          NULL,
    `end_year`            INT          NULL,
    `isolated_known_date` VARCHAR(255) NULL,
    `data_source_url`     varchar(255) null,
    `created_by`          varchar(255)          default 'Alim L.',
    `created_at`          DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `public_employees_salaries_staging`.`agency_locations`
(
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY,
    `location_name`   VARCHAR(255) NULL,
    `agency_id`       INT          NULL,
    `address_id`      INT          NULL,
    `office_type_id`  INT          NULL,
    `data_source_url` varchar(255) null,
    `created_by`      varchar(255)          default 'Alim L.',
    `created_at`      DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `public_employees_salaries_staging`.`agencies`
(
    `id`              BIGINT AUTO_INCREMENT PRIMARY KEY,
    `agency_name`     VARCHAR(255) NULL,
    `limpar_uuid`     VARCHAR(255) NULL,
    `agency_type_id`  INT          NULL,
    `data_source_url` varchar(255) null,
    `created_by`      varchar(255)          default 'Alim L.',
    `created_at`      DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `public_employees_salaries_staging`.`compensations`
(
    `id`                            BIGINT AUTO_INCREMENT PRIMARY KEY,
    `employee_work_year_id`         INT          NULL,
    `compensation_type_id`          INT          NULL,
    `value`                         VARCHAR(255) NULL,
    `payment_frequency`             VARCHAR(255) NULL,
    `is_total_compensation`         TINYINT      NULL,
    `include_in_sum_for_total_comp` TINYINT      NULL,
    `data_source_url`               varchar(255) null,
    `created_by`                    varchar(255)          default 'Alim L.',
    `created_at`                    DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `public_employees_salaries_staging`.`employee_work_years`
(
    `id`                          BIGINT AUTO_INCREMENT PRIMARY KEY,
    `employee_to_location_id`     INT          NULL,
    `location_id`                 INT          NULL,
    `agency_id`                   INT          NULL,
    `year`                        INT          NULL,
    `full_or_part_status`         VARCHAR(255) NULL,
    `pay_type`                    VARCHAR(255) NULL,
    `hourly_rate`                 VARCHAR(255) NULL,
    `job_title_id`                INT          NULL,
    `raw_dataset_table_id`        INT          NULL,
    `raw_dataset_table_id_raw_id` INT          NULL,
    `data_source_url`             varchar(255) null,
    `created_by`                  varchar(255)          default 'Alim L.',
    `created_at`                  DATETIME              DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_520_ci;