CREATE TABLE `us_courts_case_summary_court_links`
(
    `id`              bigint(20) NOT NULL AUTO_INCREMENT,
    `court_id`        smallint(6)                                 DEFAULT NULL,
    `case_id`         varchar(100) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
    `data_source_url` varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
    `aws_link`        varchar(255) COLLATE utf8mb4_unicode_520_ci DEFAULT NULL,
    `created_at`      datetime                                    DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      timestamp  NOT NULL                         DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

select id, court_id, count(*) from us_courts_case_summary_court_links group by court_id order by id;
alter table us_courts_case_summary_court_links drop column aws_link;