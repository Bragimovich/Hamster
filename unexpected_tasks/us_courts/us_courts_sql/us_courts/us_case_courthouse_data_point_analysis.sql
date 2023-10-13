use us_courts_analysis;
create table us_case_courthouse_data_point_analysis
(
    id                              bigint auto_increment primary key,
    court_id                        bigint(20),
    data_point_id                   bigint(20),
    total_distinct_values           bigint(20),
    total_null_records              bigint(20),
    total_questionable_records      bigint(20),
    created_at            datetime    default CURRENT_TIMESTAMP null,
    updated_at            timestamp   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,

    INDEX `court_id` (`court_id`),
    INDEX `data_point_id` (`data_point_id`)
);
