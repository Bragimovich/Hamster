create table crime_perps__step_1.il_woodford__mugshots
(
    id              bigint auto_increment
        primary key,
    arrestee_id     bigint                                     null,
    aws_link        varchar(255)                               null,
    original_link   varchar(255)                               null,
    notes           varchar(255)                               null,
    data_source_url varchar(255)                               null,
    created_by      varchar(255) default 'Maxim G' null,
    created_at      datetime     default CURRENT_TIMESTAMP     null,
    updated_at      timestamp    default CURRENT_TIMESTAMP     not null on update CURRENT_TIMESTAMP,
    run_id          bigint                                     null,
    touched_run_id  bigint                                     null,
    deleted         tinyint(1)   default 0                     null,
    md5_hash        varchar(255)                               null,
    UNIQUE KEY `md5` (`md5_hash`),
    INDEX `run_id` (`run_id`),
    INDEX `touched_run_id` (`touched_run_id`),
    INDEX `deleted` (`deleted`)
);

