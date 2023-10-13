create table us_courts_staging_working_copy.lawyers_law_firms
(
    lawyer_id          int unsigned                       not null,
    law_firm_id        int unsigned                       not null,
    current_law_firm   varchar(45)                        null comment 'yes/no/unknown',
    current_as_of_date varchar(45)                        null comment 'if current law firm, add date of gather here',
    created_by         varchar(255)                       not null,
    created_at         datetime default CURRENT_TIMESTAMP null,
    updated_at         datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint index1
        unique (lawyer_id, law_firm_id),
    constraint fk_lawyers_law_firms_1
        foreign key (lawyer_id) references us_courts_staging.lawyers (id),
    constraint fk_lawyers_law_firms_2
        foreign key (law_firm_id) references us_courts_staging.law_firms (id)
)
    collate = utf8mb4_unicode_520_ci;





INSERT IGNORE us_courts_staging_working_copy.lawyers_law_firms




INSERT IGNORE us_courts_staging_working_copy.lawyers_law_firms_names (lawyer_id, law_firm_id, created_by)
SELECT
    law.id   AS lawyer_id,
    firms.id AS law_firm_id,
    'Eldar Eminov' AS created_by
FROM us_courts_staging.lawyers law
         JOIN us_courts.us_case_party_lawyers_unique uniq
              ON law.external_id = uniq.id
         JOIN us_courts.us_case_laywers_mbo mbo
              ON (mbo.lawyer_name_clean = uniq.party_name_cleaned or mbo.lawyer_name = uniq.party_name)
         JOIN us_courts_staging_working_copy.law_firm_names firms
              ON firms.name = mbo.law_firm_name
WHERE mbo.lawyer_name IS NOT NULL
  AND mbo.lawyer_name != ''






