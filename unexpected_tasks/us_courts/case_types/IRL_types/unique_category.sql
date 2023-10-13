SELECT
    uctg.general_category,
    uctg.midlevel_category,
    uctg.specific_category,
    uctg.additional_category,
    pdf_link,
       court_id,
       case_id,
    unique_category_id
FROM
    (
        SELECT
            unique_category_id,
            pdf_link,
            report_text_id,
               court_id,
               case_id,
            @rn := IF(@prev = unique_category_id, @rn + 1, 1) AS rn,
            @prev := unique_category_id
        FROM litigation_case_type__IRL_pdfs_unique_categories
            JOIN (SELECT @prev := NULL, @rn := 0) AS vars
        ORDER BY unique_category_id
    ) AS T1
        JOIN litigation_case_type__IRL_unique_categories uctg on uctg.id = T1.unique_category_id
WHERE rn <= 5