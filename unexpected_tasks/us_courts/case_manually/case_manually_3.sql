create table us_courts.cases_with_pdf_manually_3
(
    year                                int,
    pub_name                          varchar(500) null,
    lead_name                          varchar(500) null,
    pdf                                 varchar(500) null,
    judge_name                          varchar(500) null,
    court_name                          varchar(500) null,
    court_id                          int null,
    case_name                           text         null,
    case_id                             varchar(500) null,
    case_filed_date                     varchar(500) null,
    case_type                           varchar(500) null,
    `Plaintiff 1 Name`                  text         null,
    `Plaintiff 1 Type`                  text         null,
    `Plaintiff 1 Sex (if Person)`       text         null,
    `Plaintiff 2 Name`                  text         null,
    `Plaintiff 2 Type`                  text         null,
    `Plaintiff 2 Sex (if Person)`       text         null,
    `Plaintiff 3 Name`                  text         null,
    `Plaintiff 3 Type`                  text         null,
    `Plaintiff 3 Sex (if Person)`       text         null,
    `Plaintiff Lawyer Name 1`           text         null,
    `Plaintiff Lawyer 1 Law Firm`       text         null,
    `Plaintiff Lawyer Name 2`           text         null,
    `Plaintiff Lawyer 2 Law Firm`       text         null,
    `Plaintiff Lawyer Name 3`           text         null,
    `Plaintiff Lawyer 3 Law Firm`       text         null,
    `Are there More Plaintiff Lawyers?` text         null,
    `Defendant 1 name`                  text         null,
    `Defendant 1 Type`                  text         null,
    `Defendant 1 Sex (if Person)`       text         null,
    `Defendant 2 name`                  text         null,
    `Defendant 2 Type`                  text         null,
    `Defendant 2 Sex (if Person)`       text         null,
    `Defendant 3 name`                  text         null,
    `Defendant 3 Type`                  text         null,
    `Defendant 3 Sex (if Person)`       text         null,
    `Defendant Lawyer Name 1`           text         null,
    `Defendant Lawyer 1 Law Firm`       text         null,
    `Defendant Lawyer Name 2`           text         null,
    `Defendant Lawyer 2 Law Firm`       text         null,
    `Defendant Lawyer Name 3`           text         null,
    `Defendant Lawyer 3 Law Firm`       text         null,
    `Are there More Defendant Lawyers?` text         null,
    notes                               text         null,
    `Done = 1`                          int          null,
    `date gathered`                     date         null,
    `ID code`                           int          null,
    `How many errors?`                  int          null,
    constraint pdf
        unique (pdf),
    INDEX case_id (case_id),
    INDEX court_id (court_id)
)
    COmMENT = 'Cases gathered manually by MBO(Rylan and etc) https://docs.google.com/spreadsheets/d/1awg3GsfbFCot_02CIj5_4wcRC7jChDZWEa8OrKpRU4k/edit#gid=127743269'
;

