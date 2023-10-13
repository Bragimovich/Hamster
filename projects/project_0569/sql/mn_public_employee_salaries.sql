CREATE TABLE `mn_public_employee_salaries_roaster`
(
  `id`               BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`           BIGINT(20),
  `temporary_id`     varchar(255) ,
  `regular_wages`    decimal(12,2),
  `overtime_wages`   decimal(12,2),
  `other_wages`      decimal(12,2),
  `total_wages`      decimal(12,2),
  `year`             int(11)      ,
  `created_by`       varchar(255) ,
  `created_at`       DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `data_source_url`  varchar(255) ,
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
    COMMENT = 'The Scrape made by ';
