CREATE TABLE `fl_ccsjcpc_case_pdfs_on_aws` (
    `id` int auto_increment primary key,
    `court_id` int,
    `case_id` varchar (255),
    `source_type` VARCHAR (255),
    `aws_link` VARCHAR (255),
    `source_link` VARCHAR (255),
    `aws_html_link` VARCHAR (255),
    -- default fields
    `deleted` INT DEFAULT 0,
    `data_source_url` VARCHAR (2048),
    `run_id` INT,
    `touched_run_id` int,
    `md5_hash` VARCHAR(100),
    `created_by` VARCHAR(255) DEFAULT 'Jaffar',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- indexes
    UNIQUE KEY `md5` (`md5_hash`), INDEX `court_id_idx` (`court_id`) ,INDEX `deleted_idx` (`deleted`)
) DEFAULT CHARSET = `utf8mb4` COLLATE = utf8mb4_unicode_520_ci COMMENT = 'Created by Jaffar Hussain, Task #0652';
