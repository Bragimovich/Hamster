CREATE TABLE `fl_ccsjcpc_case_info` (
    `id` INT auto_increment PRIMARY KEY,
    `court_id` INT,
    `case_id` VARCHAR (255),
    `case_name` VARCHAR (512) DEFAULT NULL,
    `case_filed_date` date DEFAULT NULL,
    `case_type` VARCHAR (255) DEFAULT NULL,
    `case_description` VARCHAR (255) DEFAULT NULL,
    `disposition_or_status` VARCHAR (255) DEFAULT NULL,
    `status_as_of_date` VARCHAR (255) DEFAULT NULL,
    `judge_name` VARCHAR (255) DEFAULT NULL,
    -- default fields 
    `deleted` INT DEFAULT 0,
    `data_source_url` VARCHAR (350),
    `run_id` INT,
    `touched_run_id` int,
    `md5_hash` VARCHAR(100),
    `created_by` VARCHAR(255) DEFAULT 'Jaffar',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- indexes 
    UNIQUE KEY `md5` (`md5_hash`), INDEX `court_id_idx` (`court_id`), INDEX `deleted_idx` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Jaffar Hussain, Task #0652';
