use usa_raw;
create table `words_for_matching`
(
    id              bigint auto_increment primary key,
    word            varchar(1023)                         null,
    closed          BOOLEAN            DEFAULT 0,

    created_at      datetime   default CURRENT_TIMESTAMP null,
    updated_at      timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    INDEX `word` (`word`),
    INDEX `closed` (`closed`)
)
    collate = utf8mb4_unicode_520_ci;