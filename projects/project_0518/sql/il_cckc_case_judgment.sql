create table il_cckc_case_judgment(
  `id`  int auto_increment   primary key,
  `run_id`  int,
  `touch_run_id`  int,
  `court_id`  int,
  `case_id` varchar(225),
  `complaint_id`  text DEFAULT NULL,
  `party_name`  varchar(225) DEFAULT NULL,
  `fee_amount`  varchar(225) DEFAULT NULL,
  `judgment_amount`  varchar(225) DEFAULT NULL,
  `judgment_date` date DEFAULT NULL,
  `md5_hash`  varchar (255),
  `deleted` int DEFAULT 0,
  `data_source_url`     varchar (350),
  `created_by`           VARCHAR(255)       DEFAULT 'Tauseeq',
  `created_at`           DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `scrape_frequency`  VARCHAR(255)      DEFAULT 'Weekly',
  `expected_scrape_frequency`     VARCHAR(255)      DEFAULT 'Weekly',
  `dataset_name_prefix`           VARCHAR(255)      DEFAULT  'Circuit Court of Kankakee County (500)',
  `scrape_status`          VARCHAR(255)      DEFAULT 'Live',
  UNIQUE KEY `unique_data` (`md5_hash`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
