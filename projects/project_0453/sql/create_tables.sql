CREATE TABLE `pdfs`
(
  `id`                  BIGINT(20)    AUTO_INCREMENT PRIMARY KEY,
  # begin
  `date`                DATETIME      NOT NULL,
  `pdf_link`            VARCHAR(255)  NOT NULL,
  `usa_or_world_image`  VARCHAR(10)   NOT NULL,
  # end
  `data_source_url`     TEXT          NOT NULL,
  `created_by`          VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

CREATE TABLE `powerbi_world_daily_case_counts`
(
  `id`                  BIGINT(20)   AUTO_INCREMENT PRIMARY KEY,
  # begin
  `country`             VARCHAR(255) NOT NULL,
  `confirmed_cases`     BIGINT(20)   NOT NULL DEFAULT 0,
  `data_last_updated_est` DATETIME   NOT NULL,
  `time_of_scrape_est`  DATETIME     NOT NULL,
  `date_of_scrape`      DATETIME     NOT NULL,
  # end
  `data_source_url`     TEXT         NOT NULL,
  `created_by`          VARCHAR(255)          DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME              DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
