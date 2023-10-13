create table us_courts_analysis.us_case_report_text
(
    id          bigint auto_increment
        primary key,
    court_id    bigint                                 null,
    case_id     varchar(255)                           null,

    pdf_on_aws_id bigint                               null,
    aws_link    varchar(511)                           null,
    pdf_on_aws_md5_hash varchar(255),
    text_pdf    longtext                               null,
    text_ocr    longtext                               null,
    ocr         tinyint(1)   default 0                 null,
    created_by  varchar(255) default 'Maxim G'         null,
    created_at  datetime     default CURRENT_TIMESTAMP null,
    updated_at  timestamp    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint aws_link
        unique (aws_link),
    INDEX `case_id` (`case_id`),
    INDEX `court_id` (`court_id`),
    INDEX `pdf_on_aws_id` (`pdf_on_aws_id`)

)
    collate = utf8mb4_unicode_520_ci;


