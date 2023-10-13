CREATE TABLE `fl_ccsjcpc_case_party` (
    `id` int auto_increment primary key,
    `court_id` int,
    `case_id` varchar (255),
    `is_lawyer` boolean,
    `party_name` varchar (255) DEFAULT NULL,
    `party_type` varchar (255) DEFAULT NULL,
    `law_firm` varchar (255) DEFAULT NULL,
    `party_address` varchar (255) DEFAULT NULL,
    `party_city` varchar (255) DEFAULT NULL,
    `party_state` varchar (255) DEFAULT NULL,
    `party_zip` varchar (255) DEFAULT NULL,
    `party_description` TEXT DEFAULT NULL,
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
