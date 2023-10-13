
INSERT IGNORE INTO us_courts_staging.lawyers_universities (lawyer_id, law_firm_id, created_by)
SELECT
    law.id,
    firms.id,
    'Maxim G.'
FROM us_courts.us_case_party_lawyers_unique law_o
         JOIN us_courts_staging.law_firms firms
              ON firms.name = law_o.party_law_firm_cleaned
         join us_courts_staging.lawyers law
              on law.external_id = law_o.id
WHERE law_o.party_law_firm_cleaned IS NOT NULL
  AND law_o.party_law_firm_cleaned != '';




SELECT count(*) FROM us_courts.us_case_party_lawyers_unique law_o
                  join us_courts_staging.lawyers law
                       on law.external_id = law_o.id
where party_law_firm_cleaned is not null
group by law.id;


SELECT * FROM us_courts.us_case_party_lawyers_unique law_o
                         join us_courts_staging.law_firms law
                              on law.name = law_o.party_law_firm_cleaned
where law_o.party_law_firm_cleaned is not null and law_o.party_law_firm_cleaned!=''
group by law_o.party_law_firm_cleaned;



SELECT * FROM us_courts.us_case_party_lawyers_unique law_o
where law_o.party_law_firm_cleaned is not null and law_o.party_law_firm_cleaned!=''
group by law_o.party_law_firm_cleaned;

