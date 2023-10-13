CREATE TABLE `vt_employee_salaries` (
    `id` INT auto_increment PRIMARY KEY,
    `name` VARCHAR,
    `job_title` VARCHAR,
    `department` VARCHAR,
    `job_type` VARCHAR,
    `salary` VARCHAR,
    `salary_type` VARCHAR,
    `data_as_of` DATE DEFAULT NULL,
    -- default fields 
    `deleted` INT DEFAULT 0,
    `data_source_url` VARCHAR (350),
    `run_id` INT,
    `touched_run_id` int,
    `md5_hash` VARCHAR(100),
    `created_by` VARCHAR(255) DEFAULT 'Jaffar Hussain',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- indexes 
    UNIQUE KEY `md5` (`md5_hash`), INDEX `deleted_idx` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Jaffar Hussain, Task #726';
