create table us_courts_staging.law_firm_names_addresses
(
    law_firm_name_id          int unsigned                       not null,
    law_firm_address_id       int unsigned                       not null,
    created_by        varchar(255)                       null,
    created_at        datetime default CURRENT_TIMESTAMP null,
    updated_at        datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint index1
        unique (law_firm_name_id, law_firm_address_id)
)
    collate = utf8mb4_unicode_520_ci;


INSERT INTO us_courts_staging_working_copy.law_firm_names_addresses (law_firm_name_id, law_firm_address_id, created_by)
SELECT lfn.id, lfa.id, 'Maxim G' from us_courts.us_case_lawyers__law_firms_CLEAN lf_old
join us_courts_staging_working_copy.law_firm_names lfn on lfn.name = lf_old.law_firm_name
join us_courts_staging_working_copy.law_firm_addresses lfa on lfa.street_address=lf_old.street_address
WHERE  lfa.street_address!=''


