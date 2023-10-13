CREATE TABLE `fl_ccsjcpc_case_relations_activity_pdf` (
    `id` int auto_increment primary key,
    `case_activities_md5` varchar (255),
    `case_pdf_on_aws_md5` VARCHAR (255),
    -- default fields
    `deleted` INT DEFAULT 0,
    `run_id` INT,
    `touched_run_id` int,
    `md5_hash` VARCHAR(100),
    `created_by` VARCHAR(255) DEFAULT 'Jaffar',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- indexes
    UNIQUE KEY `md5` (`md5_hash`), INDEX `deleted_idx` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Jaffar Hussain, Task #0652';
