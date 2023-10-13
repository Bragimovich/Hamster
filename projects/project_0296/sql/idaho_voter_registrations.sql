CREATE TABLE `idaho_voter_registrations`
(
  `id`                            BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                        BIGINT(20),
  `month`                         VARCHAR (255),
  `day`                           VARCHAR (255),
  `year`                          VARCHAR (255),
  `county`                        VARCHAR (255),
  `constitution`                  VARCHAR (255),
  `democratic`                    VARCHAR (255),
  `libertarian`                   VARCHAR (255),
  `republican`                    VARCHAR (255),
  `unaffiliated`                  VARCHAR (255),
  `total_registered`              VARCHAR (255),
  `scrape_dev_name`               VARCHAR(255)      DEFAULT 'Adeel',
  `data_source_url`               VARCHAR(255),
  `created_at`                    DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `scrape_frequency`              VARCHAR(255)      DEFAULT 'monthly',
  `last_scrape_date`              DATE,
  `next_scrape_date`              DATE,
  `expected_scrape_frequency`     VARCHAR(255)      DEFAULT 'monthly',
  `dataset_name_prefix`           VARCHAR(255)      DEFAULT 'idaho_voter_registrations',
  `scrape_status`                 VARCHAR(255)      DEFAULT 'Live',
  `pl_gather_task_id`             int(11)           DEFAULT '8751',
  `md5_hash` varchar(100) GENERATED ALWAYS AS (md5(CONCAT_WS('', month, day, year, county, constitution, democratic, libertarian, republican, unaffiliated, total_registered,data_source_url))) STORED,
  UNIQUE KEY `md5` (`md5_hash`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
