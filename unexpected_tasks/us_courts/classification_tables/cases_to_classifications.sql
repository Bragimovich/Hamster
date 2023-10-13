create table us_courts_staging.cases_to_classifications
(
    case_id                bigint auto_increment primary key,
    case_classification_id          bigint not null,
    created_at      datetime   default CURRENT_TIMESTAMP null,
    updated_at      timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,

    UNIQUE INDEX `classification_level` (`case_id`, `case_classification_id`)
)
comment = 'Classification table with link to cases.id and case_classifications.category_id. MT700. Made by Maxim G'
    collate = utf8mb4_unicode_520_ci;
