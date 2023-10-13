use us_courts_analysis;
create table us_case_distinct_data_points
(
    id                      bigint auto_increment primary key,
    table_id                bigint(20),
    data_point_name         varchar(500),
    direct_limpar_source    boolean,
    indirect_limpar_source  boolean,
    normalized              boolean,
    cleaned                 boolean,
    regex_question          varchar(1000),
    regex_description       varchar(1000),
    updated_at            timestamp   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,

    INDEX `table_id` (`table_id`)
);
