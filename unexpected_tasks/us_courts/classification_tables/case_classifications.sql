create table us_courts_staging.case_classification_levels
(
    category_id                bigint auto_increment primary key,

    name          varchar(500) null,
    level_id          varchar(255)  null,

    UNIQUE INDEX `classification_level` (`name`, `level_id`)

)
    collate = utf8mb4_unicode_520_ci;
