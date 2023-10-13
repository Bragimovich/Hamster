 
create table `maine_campaign_finance_contributions_csv`
 (
  `id`                        bigint AUTO_INCREMENT PRIMARY KEY,
-- Begin csv fields --
  `year`                      smallint,
  `org_id`                    bigint,
  `legacy_id`                 bigint,
  `committee_name`            varchar(255),
  `candidate_name`            varchar(255),
  `receipt_amount`            decimal(15, 2),
  `receipt_date`              date,
  `office`                    varchar(255),
  `district`                  varchar(255),
  `last_name`                 varchar(255),
  `first_name`                varchar(255),
  `middle_name`               varchar(255),
  `suffix`                    varchar(255),
  `address1`                  varchar(255),
  `address2`                  varchar(255),
  `city`                      varchar(255),
  `state`                     varchar(255),
  `zip`                       varchar(255),
  `description`               text,
  `receipt_id`                bigint,
  `filed_date`                date,
  `report_name`               varchar(255),
  `receipt_source_type`       varchar(255),
  `receipt_type`              varchar(255),
  `committee_type`            varchar(255),
  `amended`                   varchar(255),
  `employer`                  varchar(255),
  `occupation`                varchar(255),
  `occupation_comment`        varchar(255),
  `employment_information_requested`  varchar(255),
  `forgiven_loan`             varchar(255),
  `election_type`             varchar(255),
  `data_source_url`           varchar(255)        default 'https://mainecampaignfinance.com/index.html#/dataDownload' null,
-- End csv fields ------
  `created_by`                varchar(255)        default 'Frank Rao'         null,
  `created_at`                datetime            default CURRENT_TIMESTAMP   null,
  `updated_at`                timestamp           default CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP,
  `run_id`                    bigint                                          null,
  `touched_run_id`            bigint                                          null,
  `deleted`                   tinyint(1)          default 0                   null,
  `md5_hash`                  varchar(63)                                     null,
  UNIQUE KEY `unique_data` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;


