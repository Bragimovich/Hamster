create table us_court_cases.NY_case_relations_activity_pdf
(
    id                  int auto_increment primary key,
    case_activities_md5 varchar(255)                           null,
    case_pdf_on_aws_md5 varchar(255)                           null,
    created_by          varchar(255) default 'Maxim G'           null,
    created_at          datetime     default CURRENT_TIMESTAMP null,
    updated_at          timestamp    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint unique_records
        unique (case_activities_md5,case_pdf_on_aws_md5)
)   collate = utf8mb4_unicode_520_ci,
    comment = 'Table for connection with pdfs for NY court';

