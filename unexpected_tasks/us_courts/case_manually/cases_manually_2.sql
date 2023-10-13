create table us_courts.cases_with_pdf_manually_2
(
    year                                int,
    pub_name                          varchar(500) null,
    lead_name                          varchar(500) null,
    pdf                                 varchar(500) null,
    court_name                          varchar(500) null,
    court_id                            bigint,
    case_name                           text         null,
    case_id                             varchar(500) null,
    case_filed_date                     varchar(500) null,

    plaintiff_1_name                     varchar(500) null,
    plaintiff_1_law_firm                     varchar(500) null,
    plaintiff_2_name                     varchar(500) null,
    plaintiff_2_law_firm                     varchar(500) null,
    plaintiff_3_name                     varchar(500) null,
    plaintiff_3_law_firm                     varchar(500) null,

    notes                               text         null,
    `Done = 1`                          boolean          null,
    `date gathered`                     date         null,
    `ID code`                           int          null,
    created_at                     timestamp  default CURRENT_TIMESTAMP     not null,
    updated_at                     timestamp  default CURRENT_TIMESTAMP     not null on update CURRENT_TIMESTAMP,
    constraint pdf
        unique (pdf),
        INDEX case_id (case_id),
    INDEX court_id (court_id)

)

COmMENT = 'Cases gathered manually by MBO(Rylan and etc) https://docs.google.com/spreadsheets/d/1awg3GsfbFCot_02CIj5_4wcRC7jChDZWEa8OrKpRU4k/edit#gid=127743269'
;

