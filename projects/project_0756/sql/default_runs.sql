CREATE TABLE IF NOT EXISTS `usa_raw`.`us_assisted_housing_runs` (
  `id` int auto_increment primary key,
  `status` VARCHAR(255) DEFAULT 'processing',
  `created_by` VARCHAR(255) DEFAULT 'Jaffar Hussain',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `status_idx` (`status`)
) 
ENGINE = InnoDB
DEFAULT CHARSET = `utf8mb4` 
COLLATE = utf8mb4_unicode_520_ci 
COMMENT = 'Created by Jaffar Hussain, Task #756';
