create table us_courts_analysis.litigation_case_type__IRL_types_pdfs_unique_categories
(
    id                  bigint auto_increment primary key,
    unique_category_id  bigint,
    pdf_link            varchar(255)                                                                                                                   null,
    report_text_id      bigint,
    source_spreadsheet  varchar(255) default 'https://docs.google.com/spreadsheets/d/16hxEsljvBWRwnZFPPCL-fy0aNYZDcvzM4GAxhtAM56Y/edit#gid=1560615762' null,
    INDEX `report_text_id` (`report_text_id`)
)
    collate = utf8mb4_unicode_520_ci;


TRUNCATE table us_courts_analysis.litigation_case_type__IRL_unique_categories
INSERT IGNORE INTO us_courts_analysis.litigation_case_type__IRL_unique_categories (general_category, midlevel_category, specific_category, additional_category)
(SELECT DISTINCT general_category, midlevel_category, specific_category, additional_category from us_courts_analysis.litigation_case_type__IRL WHERE general_category is not null)

UPDATE litigation_case_type__IRL_unique_categories
SET midlevel_category = SUBSTRING_INDEX(midlevel_category, ' - ', -1)
UPDATE litigation_case_type__IRL_unique_categories
SET specific_category = SUBSTRING_INDEX(specific_category, ' - ', -1)
UPDATE litigation_case_type__IRL_unique_categories
SET additional_category = SUBSTRING_INDEX(additional_category, ' - ', -1)
