use us_court_cases;
# SHOW COLUMNS FROM ca_saac_case_activities;
# SHOW COLUMNS FROM ca_saac_case_relations_info_pdf;
# SHOW COLUMNS FROM ca_saac_case_info;
# SHOW COLUMNS FROM ca_saac_case_relations_activity_pdf;
# SHOW COLUMNS FROM ca_saac_case_party;
# SHOW COLUMNS FROM ca_saac_case_pdfs_on_aws;
# SHOW COLUMNS FROM ca_saac_case_additional_info;

# SELECT  data_source_url, LENGTH(data_source_url) AS mlen
# FROM    ca_saac_case_additional_info
# ORDER BY
#     mlen DESC
# LIMIT 1

use us_court_cases;
ALTER TABLE ca_saac_case_activities
    MODIFY id bigint(20) AUTO_INCREMENT,
    MODIFY court_id smallint(6) NULL,
    MODIFY case_id varchar(100) NULL,
    MODIFY activity_date date NULL,
    MODIFY activity_desc text NULL,
    MODIFY activity_type varchar(1023) NULL,
    MODIFY file text NULL,
    MODIFY md5_hash varchar(32) NULL,
    MODIFY created_by varchar(20) NULL DEFAULT 'Pospelov Vyacheslav',
    MODIFY created_at datetime NULL DEFAULT CURRENT_TIMESTAMP,
    MODIFY updated_at timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    MODIFY data_source_url varchar(255) NULL DEFAULT 'https://appellatecases.courtinfo.ca.gov/',
    MODIFY run_id bigint(20) NULL,
    MODIFY touched_run_id bigint(20) NULL,
    MODIFY deleted tinyint(1) NULL DEFAULT 0;

ALTER TABLE ca_saac_case_relations_info_pdf
    MODIFY id bigint(20) AUTO_INCREMENT,
    MODIFY case_info_md5 varchar(32) NULL,
    MODIFY case_pdf_on_aws_md5 varchar(32) NULL,
    MODIFY created_by varchar(255) NULL DEFAULT 'Pospelov Vyacheslav',
    MODIFY created_at datetime NULL DEFAULT CURRENT_TIMESTAMP,
    MODIFY updated_at timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
    #ADD court_id bigint(20) NULL


ALTER TABLE ca_saac_case_info
    MODIFY id bigint(20) AUTO_INCREMENT,
    MODIFY court_id smallint(6) NULL,
    MODIFY case_id varchar(100) NULL,
    MODIFY case_name varchar(1500) NULL,
    MODIFY case_filed_date date NULL,
    MODIFY case_type varchar(2000) NULL,
    MODIFY case_description varchar(6000) NULL,
    MODIFY disposition_or_status varchar(100) NULL,
    MODIFY status_as_of_date varchar(255) NULL,
    MODIFY judge_name varchar(255) NULL,
    MODIFY lower_court_id smallint(6) NULL,
    MODIFY lower_case_id varchar(1000) NULL,
    MODIFY md5_hash varchar(32) NULL,
    MODIFY created_by varchar(20) NULL DEFAULT 'Pospelov Vyacheslav',
    MODIFY created_at datetime NULL DEFAULT CURRENT_TIMESTAMP,
    MODIFY updated_at timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    #ADD judge_name varchar(255) NULL,
    MODIFY data_source_url varchar(255) NULL DEFAULT 'https://appellatecases.courtinfo.ca.gov/',
    MODIFY run_id bigint(20) NULL,
    MODIFY touched_run_id bigint(20) NULL,
    MODIFY deleted tinyint(1) NULL DEFAULT 0;

ALTER TABLE ca_saac_case_relations_activity_pdf
    MODIFY id bigint(20) AUTO_INCREMENT,
    MODIFY case_activities_md5 varchar(32) NULL,
    MODIFY case_pdf_on_aws_md5 varchar(32) NULL,
    MODIFY created_by varchar(255) NULL DEFAULT 'Pospelov Vyacheslav',
    MODIFY created_at datetime NULL DEFAULT CURRENT_TIMESTAMP,
    MODIFY updated_at timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    MODIFY court_id smallint(6) NULL;

ALTER TABLE ca_saac_case_party
    MODIFY id bigint(20) AUTO_INCREMENT,
    MODIFY court_id smallint(6) NULL,
    MODIFY case_id varchar(100) NULL,
    MODIFY is_lawyer int(11) NULL,
    MODIFY party_name varchar(255) NULL,
    MODIFY party_type varchar(255) NULL,
    MODIFY party_law_firm varchar(1023) NULL,
    MODIFY party_address varchar(500) NULL,
    MODIFY party_city varchar(255) NULL,
    MODIFY party_state varchar(255) NULL,
    MODIFY party_zip varchar(255) NULL,
    MODIFY party_description text NULL,
    MODIFY md5_hash varchar(32) NULL,
    MODIFY created_by varchar(20) NULL DEFAULT 'Pospelov Vyacheslav',
    MODIFY created_at datetime NULL DEFAULT CURRENT_TIMESTAMP,
    MODIFY updated_at timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    MODIFY data_source_url varchar(255) NULL DEFAULT 'https://appellatecases.courtinfo.ca.gov/',
    MODIFY run_id bigint(20) NULL,
    MODIFY touched_run_id bigint(20) NULL,
    MODIFY deleted tinyint(1) NULL DEFAULT 0;

ALTER TABLE ca_saac_case_pdfs_on_aws
    MODIFY id bigint(20) AUTO_INCREMENT,
    MODIFY court_id smallint(6) NULL,
    MODIFY case_id varchar(100) NULL,
    MODIFY source_type varchar(255) NULL DEFAULT 'info',
    MODIFY aws_link varchar(255) NULL,
    MODIFY source_link varchar(255) NULL,
    MODIFY md5_hash varchar(32) NULL,
    MODIFY created_by varchar(20) NULL DEFAULT 'Pospelov Vyacheslav',
    MODIFY created_at datetime NULL DEFAULT CURRENT_TIMESTAMP,
    MODIFY updated_at timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    MODIFY data_source_url varchar(255) NULL DEFAULT 'https://appellatecases.courtinfo.ca.gov/',
    MODIFY run_id bigint(20) NULL,
    MODIFY touched_run_id bigint(20) NULL,
    MODIFY deleted tinyint(1) NULL DEFAULT 0;

ALTER TABLE ca_saac_case_additional_info
    MODIFY id bigint(20) AUTO_INCREMENT,
    MODIFY court_id smallint(6) NULL,
    MODIFY case_id varchar(100) NULL,
    MODIFY lower_court_name varchar(255) NULL,
    MODIFY lower_case_id varchar(255) NULL,
    MODIFY lower_judge_name text NULL,
    MODIFY lower_judgement_date date NULL,
    MODIFY lower_link varchar(255) NULL,
    MODIFY disposition varchar(255) NULL,
    MODIFY md5_hash varchar(32) NULL,
    MODIFY created_by varchar(20) NULL DEFAULT 'Pospelov Vyacheslav',
    MODIFY created_at datetime NULL DEFAULT CURRENT_TIMESTAMP,
    MODIFY updated_at timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    MODIFY data_source_url varchar(255) NULL DEFAULT 'https://appellatecases.courtinfo.ca.gov/',
    MODIFY run_id bigint(20) NULL,
    MODIFY touched_run_id bigint(20) NULL,
    MODIFY deleted tinyint(1) NULL DEFAULT 0;
