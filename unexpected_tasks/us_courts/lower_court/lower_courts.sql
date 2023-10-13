use us_courts_analysis;
create table us_courts_analysis.us_case_lower_court
(
    id         bigint auto_increment primary key,
    court_id int,
    state varchar(100),
    lower_court_name          varchar(1023),
    lower_court_name_clean          varchar(511),
    lower_court_id int,

    created_by      varchar(255) default 'Maxim G'                         null,
    created_at      datetime   default CURRENT_TIMESTAMP null,
    updated_at      timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    INDEX `lower_court_name` (`lower_court_name`),
    INDEX `lower_court_id` (`lower_court_id`),
    INDEX `court_id` (`court_id`)
)
DEFAULT CHARSET = `utf8mb4`
COLLATE = utf8mb4_unicode_520_ci
COMMENT = 'Table with distinct lower court name from us_saac_case_additional_info table';


INSERT INTO us_courts_analysis.us_case_lower_court
(court_id, state, lower_court_name, lower_court_id)
SELECT us_courts_table.court_id,us_courts_table.court_state,lower_court_name, lower_court_id FROM us_courts.us_saac_case_additional_info
join us_courts.us_courts_table on us_courts_table.court_id = us_saac_case_additional_info.court_id
WHERE deleted=0 and lower_court_name is not null and lower_court_name!=''
group by lower_court_name, court_id;