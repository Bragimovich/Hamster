use us_court_cases;

alter table raw_nj_sc_case_info rename nj_sc_case_info;
alter table raw_nj_sc_case_party rename nj_sc_case_party;
alter table raw_nj_sc_case_activities rename nj_sc_case_activities;
alter table raw_nj_sc_case_pdfs_on_aws rename nj_sc_case_pdfs_on_aws;
alter table raw_nj_sc_case_relations_activity_pdf rename nj_sc_case_relations_activity_pdf;
alter table raw_nj_sc_case_additional_info rename nj_sc_case_additional_info;

CREATE TABLE `nj_sc_case_runs`
(
  `id`              BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  `status`          VARCHAR(255)       DEFAULT 'processing',
  `created_by`      VARCHAR(255)       DEFAULT 'Bhawna Pahadiya',
  `created_at`      DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;

alter table nj_sc_case_info add run_id BIGINT(20);
alter table nj_sc_case_party add run_id BIGINT(20);
alter table nj_sc_case_activities add run_id BIGINT(20);
alter table nj_sc_case_pdfs_on_aws add run_id BIGINT(20);
alter table nj_sc_case_relations_activity_pdf add run_id BIGINT(20);
alter table nj_sc_case_additional_info add run_id BIGINT(20);


CREATE INDEX run_id ON nj_sc_case_info (run_id);
CREATE INDEX run_id ON nj_sc_case_party (run_id);
CREATE INDEX run_id ON nj_sc_case_activities (run_id);
CREATE INDEX run_id ON nj_sc_case_pdfs_on_aws (run_id);
CREATE INDEX run_id ON nj_sc_case_relations_activity_pdf (run_id);
CREATE INDEX run_id ON nj_sc_case_additional_info (run_id);
