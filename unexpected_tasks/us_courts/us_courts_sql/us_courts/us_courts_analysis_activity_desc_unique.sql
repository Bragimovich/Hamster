use us_courts_analysis;
CREATE TABLE `activity_desc_unique`
(
  `id`                  BIGINT(20)    AUTO_INCREMENT PRIMARY KEY,
  # begin
  `activity_desc`       MEDIUMTEXT,
  # end
  `data_source_url`     VARCHAR(255)  NOT NULL DEFAULT 'us_courts.us_case_activities',
  `created_by`          VARCHAR(255)           DEFAULT 'Oleksii Kuts',
  `created_at`          DATETIME               DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY `activity_desc` (`activity_desc`(500)),
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  comment = 'Unique activity_desc from `us_courts.us_case_activities`...., Created by Oleksii Kuts, MultiTask #799';
