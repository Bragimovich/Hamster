CREATE TABLE `politico_categories` (
    `id` BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    `category` VARCHAR(255),
    `created_by` VARCHAR(255) DEFAULT 'Shahrukh Nawaz',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `data_source_url` VARCHAR(255),
    `run_id` BIGINT(20),
    `touched_run_id` BIGINT(20),
    `deleted` BOOLEAN DEFAULT 0,
    INDEX `run_id` (`run_id`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'press_release.politico_categories for Congress News from task 534. Made by Shahrukh Nawaz.';