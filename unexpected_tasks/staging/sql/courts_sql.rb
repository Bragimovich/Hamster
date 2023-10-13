def raw_courts
  <<~SQL
    SELECT court_id, court_name, court_state, court_type, court_sub_type
    FROM us_courts_table
    WHERE court_name NOT LIKE '%family%' AND court_id NOT IN (SELECT external_id FROM us_courts_staging.courts)
                        AND court_id IN (SELECT DISTINCT court_id
                      FROM us_case_info
                      WHERE deleted = 0 AND court_id IN (SELECT court_id FROM us_courts_table) AND case_id IS NOT NULL AND case_id != ''
                        AND (case_type NOT LIKE '%criminal%' OR case_type IS NULL) AND (case_description NOT LIKE '%criminal%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%family%' OR case_type IS NULL) AND (case_description NOT LIKE '%family%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%matrimonial%' OR case_type IS NULL) AND (case_description NOT LIKE '%matrimonial%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%traffic%' OR case_type IS NULL) AND (case_description NOT LIKE '%traffic%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%divorce%' OR case_type IS NULL) AND (case_description NOT LIKE '%divorce%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%domestic%' OR case_type IS NULL) AND (case_description NOT LIKE '%domestic%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%child support%' OR case_type IS NULL) AND (case_description NOT LIKE '%child support%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%assault%' OR case_type IS NULL) AND (case_description NOT LIKE '%assault%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%firearm%' OR case_type IS NULL) AND (case_description NOT LIKE '%firearm%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%theft%' OR case_type IS NULL) AND (case_description NOT LIKE '%theft%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%small claims%' OR case_type IS NULL) AND (case_description NOT LIKE '%small claims%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%change of name%' OR case_type IS NULL) AND (case_description NOT LIKE '%change of name%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%guardian%' OR case_type IS NULL) AND (case_description NOT LIKE '%guardian%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%fmly%' OR case_type IS NULL) AND (case_description NOT LIKE '%fmly%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%parent%' OR case_type IS NULL) AND (case_description NOT LIKE '%parent%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '% violent%' OR case_type IS NULL) AND (case_description NOT LIKE '% violent%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%Custody%' OR case_type IS NULL) AND (case_description NOT LIKE '%Custody%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%murder%' OR case_type IS NULL) AND (case_type NOT LIKE '%child%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%manslaughter%' OR case_type IS NULL)
                        AND !(case_description IS NOT NULL AND case_description LIKE '%rape%' AND case_type IS NULL) 
                        AND !(case_description IS NOT NULL AND case_description LIKE '%SEXUAL IMPOSITION%' AND case_type IS NULL)
                        AND !(case_description IS NOT NULL AND case_description LIKE '%SEX OFFENSES%' AND case_type IS NULL) 
                        AND !(case_description IS NOT NULL AND case_description LIKE '%Bail Review%' AND case_type IS NULL)
                        AND !(case_description IS NOT NULL AND case_description LIKE '%robbery%' AND case_type IS NULL) 
                        AND !(case_description IS NOT NULL AND case_description LIKE '%substance%' AND case_description LIKE '%controll%' AND case_type IS NULL)
                        AND !(case_description IS NOT NULL AND case_description LIKE '%crime%' AND case_type LIKE '%Discipline%')
                        AND (case_type NOT LIKE '%poPROTECTIVE ORDER COURT%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%FC- PETITION FOR ALIMONY.%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%PET FOR PAR RESP CHILD VISITAT%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%PR Guardian/Conserv - Adult%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Annulment%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Driving Under the Influence%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Legacy - Family Law%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Visitation%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%PETITION FOR ALIMONY.%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%K.S.A 60-1507%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Conviction of crime%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%POSSESSION $___ & COST FED%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%PCRA%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Burglary%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Rape%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Robbery%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Terrorist%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Sexual Conduct%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Corruption of Minors%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Crime%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Bail Appeal%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Resisting Arrest%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Unlawful Contact%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Incest%' OR case_type IS NULL))
                    OR court_id IN (SELECT DISTINCT court_id
                      FROM us_saac_case_info
                      WHERE deleted = 0 AND court_id IN (SELECT court_id FROM us_courts_table) AND case_id IS NOT NULL AND case_id != ''
                        AND (case_type NOT LIKE '%criminal%' OR case_type IS NULL) AND (case_description NOT LIKE '%criminal%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%family%' OR case_type IS NULL) AND (case_description NOT LIKE '%family%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%matrimonial%' OR case_type IS NULL) AND (case_description NOT LIKE '%matrimonial%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%traffic%' OR case_type IS NULL) AND (case_description NOT LIKE '%traffic%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%divorce%' OR case_type IS NULL) AND (case_description NOT LIKE '%divorce%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%domestic%' OR case_type IS NULL) AND (case_description NOT LIKE '%domestic%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%child support%' OR case_type IS NULL) AND (case_description NOT LIKE '%child support%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%assault%' OR case_type IS NULL) AND (case_description NOT LIKE '%assault%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%firearm%' OR case_type IS NULL) AND (case_description NOT LIKE '%firearm%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%theft%' OR case_type IS NULL) AND (case_description NOT LIKE '%theft%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%small claims%' OR case_type IS NULL) AND (case_description NOT LIKE '%small claims%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%change of name%' OR case_type IS NULL) AND (case_description NOT LIKE '%change of name%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%guardian%' OR case_type IS NULL) AND (case_description NOT LIKE '%guardian%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%fmly%' OR case_type IS NULL) AND (case_description NOT LIKE '%fmly%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%parent%' OR case_type IS NULL) AND (case_description NOT LIKE '%parent%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '% violent%' OR case_type IS NULL) AND (case_description NOT LIKE '% violent%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%Custody%' OR case_type IS NULL) AND (case_description NOT LIKE '%Custody%' OR case_description IS NULL)
                        AND (case_type NOT LIKE '%murder%' OR case_type IS NULL) AND (case_type NOT LIKE '%child%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%manslaughter%' OR case_type IS NULL)
                        AND !(case_description IS NOT NULL AND case_description LIKE '%rape%' AND case_type IS NULL) 
                        AND !(case_description IS NOT NULL AND case_description LIKE '%SEXUAL IMPOSITION%' AND case_type IS NULL)
                        AND !(case_description IS NOT NULL AND case_description LIKE '%SEX OFFENSES%' AND case_type IS NULL) 
                        AND !(case_description IS NOT NULL AND case_description LIKE '%Bail Review%' AND case_type IS NULL)
                        AND !(case_description IS NOT NULL AND case_description LIKE '%robbery%' AND case_type IS NULL) 
                        AND !(case_description IS NOT NULL AND case_description LIKE '%substance%' AND case_description LIKE '%controll%' AND case_type IS NULL)
                        AND !(case_description IS NOT NULL AND case_description LIKE '%crime%' AND case_type LIKE '%Discipline%')
                        AND (case_type NOT LIKE '%poPROTECTIVE ORDER COURT%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%FC- PETITION FOR ALIMONY.%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%PET FOR PAR RESP CHILD VISITAT%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%PR Guardian/Conserv - Adult%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Annulment%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Driving Under the Influence%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Legacy - Family Law%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Visitation%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%PETITION FOR ALIMONY.%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%K.S.A 60-1507%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Conviction of crime%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%POSSESSION $___ & COST FED%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%PCRA%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Burglary%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Rape%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Robbery%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Terrorist%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Sexual Conduct%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Corruption of Minors%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Crime%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Bail Appeal%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Resisting Arrest%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Unlawful Contact%' OR case_type IS NULL)
                        AND (case_type NOT LIKE '%Incest%' OR case_type IS NULL));
  SQL
end