
CREATE TABLE `hle_resources`.`captcha_statistics`
(
  `id`                    BIGINT AUTO_INCREMENT PRIMARY KEY,

  `project_number`        VARCHAR(15)                           NOT NULL,
  `adapter`               VARCHAR(31)                           NOT NULL,
  `solution`              VARCHAR(63)                           NOT NULL,
  `is_solved`             TINYINT(1)  DEFAULT 0                 NULL,
  `website_url`           TEXT                                  NULL,
  `payload`               JSON,
  `response`              JSON,

  `created_at`            DATETIME    DEFAULT CURRENT_TIMESTAMP NOT NULL
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'captcha_adapter for CaptchaAdapter Created by William Devries';

