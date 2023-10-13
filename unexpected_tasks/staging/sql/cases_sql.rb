
def raw_cases(limit)
  <<~SQL
    SELECT ci.id AS id, court_id, case_id, case_name, case_filed_date, case_type,
      case_description, ifnull(ifnull(ifnull(cleaned_status_as_of_date, cleaned_disposition_or_status),disposition_or_status),status_as_of_date) AS status,
      data_source_url, priority, general_category, TRIM(SUBSTRING_INDEX(midlevel_category,' - ', -1)) AS midlevel_category,
      TRIM(SUBSTRING_INDEX(specific_category,' - ', -1)) AS specific_category,
      TRIM(SUBSTRING_INDEX(additional_category,' - ', -1)) AS additional_category
    FROM us_case_info AS ci
      LEFT JOIN us_courts_analysis.litigation_case_type__IRL AS lct
        ON lct.`values` = TRIM(REPLACE(ci.case_type,'\n',''))
    WHERE ci.deleted = 0 AND ci.checked = 0 AND court_id in (select external_id from us_courts_staging.courts) AND ci.case_id IS NOT NULL and ci.case_id != ''
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
      AND (case_type NOT LIKE '%Incest%' OR case_type IS NULL) 
    LIMIT #{limit};
  SQL
end

def raw_complaint(raw_id, raw_court_id)
  <<~SQL
    SELECT CONCAT('https://court-cases-activities.s3.amazonaws.com/',pdf.file) AS file
    FROM us_case_activities AS act
      JOIN us_case_activities_pdf AS pdf
        ON pdf.activity_id = act.id
    WHERE activity_decs LIKE '%complaint%'
      AND act.case_id = '#{raw_id}' AND act.court_id = '#{raw_court_id}'
    LIMIT 1;
  SQL
end

def raw_appeal(raw_id, raw_court_id)
  <<~SQL
    SELECT CONCAT('https://court-cases-activities.s3.amazonaws.com/',pdf.file) AS file
    FROM us_case_activities AS act
      JOIN us_case_activities_pdf AS pdf
        ON pdf.activity_id = act.id
    WHERE activity_decs LIKE '%appeal%'
      AND act.case_id = '#{raw_id}' AND act.court_id = '#{raw_court_id}'
    LIMIT 1;
  SQL
end

def raw_summary(raw_id, raw_court_id)
  <<~SQL
    SELECT aws_link AS file
    FROM us_case_pdfs_on_aws 
    WHERE source_type = 'info' 
      AND court_id = '#{raw_court_id}' 
      AND case_id = '#{raw_id}' 
    LIMIT 1;
  SQL
end

def raw_cases_saac(limit)
  <<~SQL
    SELECT ci.id AS id, court_id, case_id, case_name, case_filed_date, case_type,
      case_description, ifnull(status_as_of_date, disposition_or_status) AS status,
      data_source_url, priority, general_category, TRIM(SUBSTRING_INDEX(midlevel_category,' - ', -1)) AS midlevel_category,
      TRIM(SUBSTRING_INDEX(specific_category,' - ', -1)) AS specific_category,
      TRIM(SUBSTRING_INDEX(additional_category,' - ', -1)) AS additional_category
    FROM us_saac_case_info AS ci
      LEFT JOIN us_courts_analysis.litigation_case_type__IRL AS lct
        ON lct.`values` = TRIM(REPLACE(ci.case_type,'\n',''))
    WHERE ci.deleted = 0 AND ci.checked = 0 AND court_id in (select external_id from us_courts_staging.courts)
      AND case_id IS NOT NULL AND case_id != ''
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
      AND (case_type NOT LIKE '%Incest%' OR case_type IS NULL) 
    LIMIT #{limit};
  SQL
end

def raw_complaint_saac(raw_id, raw_court_id)
  <<~SQL
    SELECT aws_link AS file
    FROM us_saac_case_activities AS act
      JOIN us_saac_case_relations_activity_pdf AS rel
        ON rel.case_activities_md5 = act.md5_hash
      JOIN us_saac_case_pdfs_on_aws AS aws
        ON aws.md5_hash = rel.case_pdf_on_aws_md5
    WHERE act.activity_desc LIKE '%complaint%'
      AND act.case_id = '#{raw_id}' AND act.court_id = '#{raw_court_id}'
    LIMIT 1;
  SQL
end

def raw_appeal_saac(raw_id, raw_court_id)
  <<~SQL
    SELECT aws_link AS file
    FROM us_saac_case_activities AS act
      JOIN us_saac_case_relations_activity_pdf AS rel
        ON rel.case_activities_md5 = act.md5_hash
      JOIN us_saac_case_pdfs_on_aws AS aws
        ON aws.md5_hash = rel.case_pdf_on_aws_md5
    WHERE act.activity_desc LIKE '%appeal%'
      AND act.case_id = '#{raw_id}' AND act.court_id = '#{raw_court_id}'
    LIMIT 1;
  SQL
end

def raw_summary_saac(raw_id, raw_court_id)
  <<~SQL
    SELECT aws_link AS file
    FROM us_saac_case_pdfs_on_aws
    WHERE source_type = 'info'
      AND case_id = '#{raw_id}' 
      AND court_id = '#{raw_court_id}'
    LIMIT 1;
  SQL
end

def uuid
  <<~SQL
    UPDATE cases
    SET generated_uuid = LOWER(CONCAT(HEX(RANDOM_BYTES(4)), '-', HEX(RANDOM_BYTES(2)), '-4', 
                        SUBSTR(HEX(RANDOM_BYTES(2)), 2, 3), '-', concat(HEX(FLOOR(ASCII(RANDOM_BYTES(1)) / 64)+8), 
                        SUBSTR(HEX(RANDOM_BYTES(2)), 2, 3)), '-', HEX(RANDOM_BYTES(6))))
    WHERE generated_uuid IS NULL;
  SQL
end

def categories_from_raw_type
  <<~SQL
    UPDATE cases AS ca
      JOIN us_courts_analysis.us_case_keyword_to_unique_raw_type_category AS udc
        ON ca.raw_type = udc.raw_type
      JOIN us_courts_analysis.litigation_case_type__IRL_unique_categories AS uc
        ON uc.id = udc.category_id
    SET ca.type = uc.general_category, ca.category = uc.midlevel_category, ca.subcategory = uc.specific_category, 
        ca.additional_subcategory = uc.additional_category
    WHERE ca.type IS NULL;
  SQL
end

def categories_from_description
  <<~SQL
    UPDATE cases AS ca
      JOIN us_courts_analysis.us_case_keyword_to_unique_description_category AS udc
        ON ca.description = udc.description
      JOIN us_courts_analysis.litigation_case_type__IRL_unique_categories AS uc
        ON uc.id = udc.category_id
    SET ca.type = uc.general_category, ca.category = uc.midlevel_category, ca.subcategory = uc.specific_category, 
        ca.additional_subcategory = uc.additional_category
    WHERE ca.type IS NULL;
  SQL
end

def categories_from_text
  <<~SQL
    UPDATE cases AS ca
      JOIN courts AS co
        ON ca.court_id = co.id
      JOIN us_courts_analysis.us_case_report_text AS rt
        ON rt.case_id = ca.raw_id AND rt.court_id = co.external_id
      JOIN us_courts_analysis.us_case_pdfs_unique_categories AS uc
        ON rt.id = uc.case_report_text_id
      JOIN us_courts_analysis.litigation_case_type__IRL_unique_categories AS irl
        ON irl.id = uc.unique_category_id
    SET ca.type = irl.general_category, ca.category = irl.midlevel_category, ca.subcategory = irl.specific_category, 
        ca.additional_subcategory = irl.additional_category
    WHERE ca.type IS NULL;
  SQL
end

def categories_from_pdf_text
  <<~SQL
    UPDATE cases AS ca
      JOIN courts AS co
        ON co.id = ca.court_id
      JOIN us_courts_analysis.litigation_keyword_to_case AS kc
        ON kc.case_id = ca.raw_id AND kc.court_id = co.external_id
      JOIN us_courts_analysis.litigation_case_type__IRL_keywords AS k
        ON kc.keyword = k.keyword
      JOIN us_courts_analysis.litigation_case_type__IRL_unique_categories AS uc 
        ON k.unique_category_id = uc.id
    SET ca.type = uc.general_category, ca.category = uc.midlevel_category, ca.subcategory = uc.specific_category,
        ca.additional_subcategory = uc.additional_category
    WHERE ca.type IS NULL;
  SQL
end

def categories_from_keywords_general
  <<~SQL
    UPDATE cases AS ca
      JOIN courts AS co
		    ON co.id = ca.court_id
      JOIN us_courts_analysis.litigation_keyword_to_case AS kc 
    	  ON kc.case_id = ca.raw_id AND kc.court_id = co.external_id
      JOIN us_courts_analysis.litigation_case_type__IRL_unique_categories AS uc_1
		    ON uc_1.general_category = kc.keyword AND uc_1.midlevel_category IS NULL
    SET ca.type = uc_1.general_category, ca.category = uc_1.midlevel_category, ca.subcategory = uc_1.specific_category,
        ca.additional_subcategory = uc_1.additional_category
    WHERE ca.type IS NULL;
  SQL
end

def categories_from_keywords_midlevel
  <<~SQL
    UPDATE cases AS ca
      JOIN courts AS co
    	  ON co.id = ca.court_id
      JOIN us_courts_analysis.litigation_keyword_to_case AS kc 
    	  ON kc.case_id = ca.raw_id AND kc.court_id = co.external_id
      JOIN us_courts_analysis.litigation_case_type__IRL_unique_categories AS uc_2
		    ON uc_2.midlevel_category = kc.keyword AND uc_2.specific_category IS NULL
    SET ca.type = uc_2.general_category, ca.category = uc_2.midlevel_category, ca.subcategory = uc_2.specific_category,
        ca.additional_subcategory = uc_2.additional_category
    WHERE ca.type IS NULL;
  SQL
end

def categories_from_keywords_specific
  <<~SQL
    UPDATE cases AS ca
      JOIN courts AS co 
    	  ON co.id = ca.court_id
      JOIN us_courts_analysis.litigation_keyword_to_case AS kc 
    	  ON kc.case_id = ca.raw_id AND kc.court_id = co.external_id
      JOIN us_courts_analysis.litigation_case_type__IRL_unique_categories AS uc_3
        ON uc_3.specific_category = kc.keyword AND uc_3.additional_category IS NULL
    SET ca.type = uc_3.general_category, ca.category = uc_3.midlevel_category, ca.subcategory = uc_3.specific_category,
        ca.additional_subcategory = uc_3.additional_category
    WHERE ca.type IS NULL;
  SQL
end

def categories_from_keywords_additional
  <<~SQL
    UPDATE  us_courts_staging.cases AS ca
      JOIN us_courts_staging.courts AS co 
    	  ON co.id = ca.court_id
      JOIN us_courts_analysis.litigation_keyword_to_case AS kc 
    	  ON kc.case_id = ca.raw_id AND kc.court_id = courts.external_id
      JOIN us_courts_analysis.litigation_case_type__IRL_unique_categories AS uc_4
        ON uc_4.additional_category = kc.keyword
    SET ca.type = uc_4.general_category, ca.category = uc_4.midlevel_category, ca.subcategory = uc_4.specific_category,
        ca.additional_subcategory = uc_4.additional_category
    WHERE ca.type IS NULL;
  SQL
end
