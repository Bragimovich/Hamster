 
create table `maine_campaign_finance_committees_json`
 (
  `id`                        bigint AUTO_INCREMENT PRIMARY KEY,
-- Begin csv fields --
  `committee_name`              varchar(255),
  `committee_type`              varchar(255),
  `committee_address`           varchar(255),
  `phone`                       varchar(255),
  `election_year`               smallint,
  `status`                      varchar(255),
  `total_contributions`         int,
  `total_expenditures`          decimal(15,2),
  `pac_type`                    varchar(255),
  `party`                       varchar(255),
  `id_number`                   varchar(255),
  `date_registered`             varchar(255),
  `treasurer`               varchar(255),
  `office_id`               bigint,
  `election_id`             bigint,
  `district_id`             bigint,
  `election_cycle_id`       bigint,
  `registration_id`         bigint,
  `row_number`              bigint,
  `total_rows`              bigint,
  `founding_organization`       varchar(255),
  `ballot_questions_details`    varchar(255),
  `jurisdiction_type`           varchar(255),
  `email`                       varchar(255),
  `principal_officer`           varchar(255),
  `committee_type_code`         varchar(255),
  `data_source_url`           varchar(255)        default 'https://mainecampaignfinance.com/index.html#/exploreCommittee' null,
-- End csv fields ------
  `created_by`                varchar(255)        default 'Frank Rao'         null,
  `created_at`                datetime            default CURRENT_TIMESTAMP   null,
  `updated_at`                timestamp           default CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP,
  `run_id`                    bigint                                          null,
  `touched_run_id`            bigint                                          null,
  `deleted`                   tinyint(1)          default 0                   null,
  `md5_hash`                  varchar(255)                                     null,
  UNIQUE KEY `unique_data` (`md5_hash`),
  INDEX `run_id` (`run_id`),
  INDEX `touched_run_id` (`touched_run_id`),
  INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci;


