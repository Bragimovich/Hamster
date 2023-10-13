create table `words_matched`
(
    id              bigint auto_increment primary key,
    word_id         bigint(20)                  not null,
    matched_row_id         bigint(20)                  not null,
    table_name      varchar(255)                null,

    created_at      datetime   default CURRENT_TIMESTAMP null,
    updated_at      timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    INDEX `word_id` (`word_id`),
    INDEX `text_id` (`text_id`)
)
    collate = utf8mb4_unicode_520_ci;