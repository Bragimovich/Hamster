create table us_courts.cl_courts_clean
(
    id                        bigint auto_increment
        primary key,
    court_id                    bigint                                 null,
    cl_court_id                  varchar(20)                            null,

    court_short_name          varchar(255)                           null,
    court_full_name           varchar(255)                           null,
    court_url                 varchar(255)                           null,
    court_start_date          datetime                               null,
    court_end_date            datetime                               null,
    court_jurisdiction        varchar(50)                            null,

    created_by                varchar(255) default 'Maxim G'    null,
    created_at                datetime     default CURRENT_TIMESTAMP null,
    updated_at                datetime     default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint court_id
        unique (court_id),
    INDEX cl_court_id (cl_court_id)
)
    comment 'Cleaned Courts from CourtListener.com...., Created by Oleksii Kuts, Task #470' collate = utf8mb4_unicode_520_ci;


UPDATE us_courts.cl_courts_clean cc
    JOIN us_courts.us_courts_table ct on ct.court_name = cc.court_full_name
SET cc.court_id = ct.court_id

