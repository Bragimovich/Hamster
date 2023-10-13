create table us_courts_analysis.analysis_litigation_IRL__categories
(
    id                bigint auto_increment
        primary key,

    category_name          varchar(500) null,
    category_column          varchar(255)  null,

    UNIQUE INDEX `categories` (`category_name`, `category_column`)

)
    collate = utf8mb4_unicode_520_ci;


TRUNCATE table us_courts_analysis.analysis_litigation_IRL__categories

INSERT IGNORE INTO us_courts_analysis.analysis_litigation_IRL__categories (category_name, category_column)
SELECT general_category, 'general_category' from us_courts_analysis.litigation_case_type__IRL WHERE general_category is not null order by general_category

INSERT IGNORE INTO us_courts_analysis.analysis_litigation_IRL__categories (category_name, category_column)
SELECT SUBSTRING_INDEX(midlevel_category, ' - ', -1) as c, 'midlevel_category' from us_courts_analysis.litigation_case_type__IRL WHERE midlevel_category is not null order by c

INSERT IGNORE INTO us_courts_analysis.analysis_litigation_IRL__categories (category_name, category_column)
SELECT SUBSTRING_INDEX(specific_category, ' - ', -1) as c, 'specific_category' from us_courts_analysis.litigation_case_type__IRL WHERE specific_category is not null order by c

INSERT IGNORE INTO us_courts_analysis.analysis_litigation_IRL__categories (category_name, category_column)
    SELECT SUBSTRING_INDEX(additional_category, ' - ', -1) as c, 'additional_category' from us_courts_analysis.litigation_case_type__IRL WHERE additional_category is not null order by c


UPDATE us_courts_analysis.analysis_litigation_IRL__categories
SET category_name = SUBSTRING_INDEX(category_name, ' - ', -1)
