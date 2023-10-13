use press_releases;
create table us_dept_ways_and_means
(
    id   int auto_increment   primary key,
    bar_number               varchar(255) null,
    title   varchar null,
    teaser text,
    article longtext,
    link varchar (unique key),
    creator varchar default 'House Committee on Ways and Means',
    type varchar (use downcase to fill this column)  default value  'press release',
    country varchar default 'US',
    date datetime,
    dirty_news tinyint(1),
    with_table tinyint(1),

    scrape_frequency varchar(255)  DEFAULT 'daily',
    data_source_url  VARCHAR(255),
    created_by      VARCHAR(255),
    created_at      DATETIME           DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    run_id                  bigint                                   null,
    touched_run_id          bigint                                   null,
    deleted                 tinyint(1)         default 0               null,
    md5_hash                varchar(255)                               null
);


create index bar_number
    on press_releases.us_dept_ways_and_means (bar_number);

create index touched_run_id
    on press_releases.us_dept_ways_and_means (touched_run_id);
