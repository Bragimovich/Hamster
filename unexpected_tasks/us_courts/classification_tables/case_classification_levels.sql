create table us_courts_staging.case_classifications
(
    level_id                bigint auto_increment primary key,

    name          varchar(500) null,
    level          varchar(255)  null,

    UNIQUE INDEX `classifications` (`name`, `level`)

)
    collate = utf8mb4_unicode_520_ci;
