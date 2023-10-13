alter table az_assessment add `md5_hash` varchar(32) DEFAULT NULL AFTER `data_type`, add index(`md5_hash`);
alter table az_assessment add `deleted` boolean DEFAULT 0 AFTER `md5_hash`, add index(`deleted`);
alter table az_assessment CHANGE `created_at` `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
alter table az_assessment add `fay_status` varchar(15) DEFAULT NULL AFTER `subgroup`;

alter table `az_enrollment` add column `md5_hash` varchar(32) DEFAULT NULL AFTER `data_type`, add index md5 (`md5_hash`);
alter table `az_enrollment` add column `deleted` boolean DEFAULT 0 AFTER `md5_hash`, add index(`deleted`);

alter table `az_dropout` add column `md5_hash` varchar(32) DEFAULT NULL AFTER `data_type`, add index md5 (`md5_hash`);
alter table `az_dropout` add column `deleted` boolean DEFAULT 0 AFTER `md5_hash`, add index(`deleted`);


alter table `az_cohort` add column `md5_hash` varchar(32) default null after `data_type`, add index md5 (`md5_hash`);
alter table `az_cohort` add column `deleted` boolean DEFAULT 0 AFTER `md5_hash`, add index(`deleted`);
alter table `az_cohort` add column `percent_graduated_in_5_years` varchar(255) after `percent_graduated_in_4_years`;
alter table `az_cohort` add column `percent_graduated` varchar(255) after `percent_graduated_in_5_years`;


alter table `az_assessment` add column `run_id` bigint(20) default null after `update_at`;
alter table `az_assessment` add column `touched_run_id` bigint(20) default null after `run_id`;

alter table `az_assessment_aims` add column `run_id` bigint(20) default null after `update_at`;
alter table `az_assessment_aims` add column `touched_run_id` bigint(20) default null after `run_id`;

alter table `az_assessment_azella` add column `run_id` bigint(20) default null after `update_at`;
alter table `az_assessment_azella` add column `touched_run_id` bigint(20) default null after `run_id`;

alter table `az_assessment_azmerit` add column `run_id` bigint(20) default null after `update_at`;
alter table `az_assessment_azmerit` add column `touched_run_id` bigint(20) default null after `run_id`;


alter table `az_assessment_azmerit_msaa` add column `run_id` bigint(20) default null after `update_at`;
alter table `az_assessment_azmerit_msaa` add column `touched_run_id` bigint(20) default null after `run_id`;

alter table `az_cohort` add column `run_id` bigint(20) default null after `update_at`;
alter table `az_cohort` add column `touched_run_id` bigint(20) default null after `run_id`;

alter table `az_dropout` add column `run_id` bigint(20) default null after `update_at`;
alter table `az_dropout` add column `touched_run_id` bigint(20) default null after `run_id`;

alter table `az_enrollment` add column `run_id` bigint(20) default null after `update_at`;
alter table `az_enrollment` add column `touched_run_id` bigint(20) default null after `run_id`;


alter table `az_general_info_matched` add column `created_by` varchar(255) default null;
alter table `az_general_info_matched` add column `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
alter table `az_general_info_matched` add column `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP; 

alter table `az_general_info_matched` add column `run_id` bigint(20) default null after `updated_at`;
alter table `az_general_info_matched` add column `touched_run_id` bigint(20) default null after `run_id`;


ALTER TABLE az_assessment_aims CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;
ALTER TABLE az_assessment_azmerit CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;
ALTER TABLE az_general_info_matched CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;


