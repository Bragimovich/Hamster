 
create table `maine_campaign_finance_candidates_json`
 (
  `id`                        bigint AUTO_INCREMENT PRIMARY KEY,
-- Begin csv fields --
  `candidate_name`			varchar(255),
  `office_name`				  varchar(255),
  `election_year`				smallint,
  `election_year_str`		varchar(255),
  `party`				        varchar(255),
  `district`				    varchar(255),
  `jurisdiction`				varchar(255),
  `finance_type`				varchar(255),
  `status`				      varchar(255),
  `incumbent`				    varchar(255),
  `id_number`				    bigint,
  `treasurer_name`				varchar(255),
  `candidate_address`				varchar(255),
  `registration_date`				date,
  `public_phone_number`				varchar(255),
  `political_party_committee_name`				varchar(255),
  `candidate_status`				    varchar(255),
  `officer_holder_status`				varchar(255),
  `election_name`				        varchar(255),
  `numberof_candidates`				bigint,
  `office_id`				          bigint,
  `election_id`				        bigint,
  `district_id`				        bigint,
  `election_cycle_id`				  bigint,
  `office_type`				        varchar(255),
  `jurisdiction_id`				    bigint,
  `display_order`				      bigint,
  `registration_id`				    bigint,
  `email`				              varchar(255),
  `finance_status`				    varchar(255),
  `row_number`				        bigint,
  `total_rows`				        bigint,
  `unregistered_candidate`		bigint,
  `incumbent_flag`				    tinyint(1) default '0' null,
  `total_contributions`				int,
  `total_expenditures`				int,
  `total_inkind_contributions`				int,
  `total_cashon_hand`				  int,
  `primary_result`				    varchar(255),
  `general_result`				    varchar(255),
  `gender`				            varchar(255),
  `data_source_url`           varchar(255)        default 'https://mainecampaignfinance.com/index.html#/explore/candidate' null,
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


