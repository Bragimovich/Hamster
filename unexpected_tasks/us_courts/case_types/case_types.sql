use us_courts;
create table us_case_type_categories_id
(
    id         bigint auto_increment primary key,
    name         varchar(255)                         null,
    category     varchar(255)                         null,

    created_by      varchar(255) default 'Maxim G'                         null,
    created_at      datetime   default CURRENT_TIMESTAMP null,
    updated_at      timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,

    constraint name_category
        unique (name, category)
)
    collate = utf8mb4_unicode_520_ci;




use us_courts;
create table us_case_type_categories
(
    id         bigint auto_increment primary key,
    case_id         varchar(255)                         null,
    court_id         varchar(255)                         null,
    case_type_category_id     bigint(20)                null,


    created_by      varchar(255) default 'Maxim G'                         null,
    created_at      datetime   default CURRENT_TIMESTAMP null,
    updated_at      timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,

    constraint case_type_category
        unique (case_id, court_id, case_type_category_id)
)
    collate = utf8mb4_unicode_520_ci;



