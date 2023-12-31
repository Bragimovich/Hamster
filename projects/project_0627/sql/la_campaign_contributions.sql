CREATE TABLE `la_campaign_contributions`
(
  `id`                        BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `run_id`                    INT,
  `filer_name`                VARCHAR (255),
  `report`                    VARCHAR (255),
  `report_link`               VARCHAR (255),
  `type`                      VARCHAR (255),
  `source_name`               VARCHAR (255),
  `source_complete_address`   VARCHAR (255),
  `source_address`            VARCHAR (255),
  `source_city`               VARCHAR (255),
  `source_state`              VARCHAR (255),
  `source_zip`                VARCHAR (255),
  `description`               VARCHAR (255),
  `contribution_date`         Date,
  `amount`                    DECIMAL(12,2),
  `created_at`                DATETIME          DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_by`           VARCHAR(255)      DEFAULT 'Adeel',
  `data_source_url`           VARCHAR(255)      DEFAULT "https://www.ethics.la.gov/CampaignFinanceSearch/SearchResultsByContributions.aspx",
  `last_scrape_date`          DATE,
  `next_scrape_date`          DATE,
  `md5_hash`                  Varchar(100) GENERATED ALWAYS AS (md5(CONCAT_WS('',filer_name, report, report_link, type, source_name, source_complete_address, description, CAST(contribution_date as CHAR), CAST(amount as CHAR)))) STORED,
  `scrape_frequency`          VARCHAR(255) DEFAULT 'Daily',
  `deleted`                   BOOLEAN DEFAULT 0,
  INDEX `date_index` (`contribution_date`),
  INDEX `filer_index`(`report`),
  INDEX `amount_index` (`amount`)
)DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;
