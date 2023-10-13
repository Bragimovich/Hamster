CREATE TABLE `scrape_tasks_attached_tables`
(
  `id`                BIGINT(20)         AUTO_INCREMENT PRIMARY KEY,
  # BEGIN tables checker
    `task_number`     INT                NOT NULL,
    `current_state`   TEXT               NOT NULL,
  # END
  `data_source_url`   VARCHAR(255)       DEFAULT 'https://lokic.locallabs.com/api/v1/scrape_tasks/',
  `created_by`        VARCHAR(255)       DEFAULT 'Oleksii Kuts',
  `created_at`        DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`           BOOLEAN            DEFAULT 0,
  INDEX `task_number` (`task_number`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'attached tables history for scrape_task_tables_checker, ...., Created by Oleksii Kuts, MultiTask #873';

CREATE TABLE `scrape_tasks_attached_tables_sent_counter`
(
  `id`                BIGINT(20)         AUTO_INCREMENT PRIMARY KEY,
  # BEGIN alert log
    `task_number`     INT                NOT NULL,
    `sent_counter`    INT                NOT NULL default 0,
  # END
  `created_at`        DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `task_number` (`task_number`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT = 'Slack sending messages counter for every task for scrape_task_tables_checker, ...., Created by Oleksii Kuts, MultiTask #873';
