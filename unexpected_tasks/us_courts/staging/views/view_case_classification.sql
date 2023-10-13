CREATE OR REPLACE VIEW us_courts_staging.view_case_classification
AS
    SELECT c2c.case_id case_id, cc.name type, c2.name category, c3.name subcategory, c4.name additional_subcategory FROM us_courts_staging.cases_to_classifications c2c
            JOIN us_courts_staging.case_classifications cc on c2c.case_classification_id=cc.category_id and level=1
        LEFT JOIN (SELECT case_id, cc.name
                    FROM us_courts_staging.cases_to_classifications c2c
                    JOIN us_courts_staging.case_classifications cc on c2c.case_classification_id=cc.category_id and level=2) c2 on c2.case_id =c2c.case_id
        LEFT JOIN (SELECT case_id, cc.name
                    FROM us_courts_staging.cases_to_classifications c2c
                    JOIN us_courts_staging.case_classifications cc on c2c.case_classification_id=cc.category_id and level=3) c3 on c3.case_id =c2c.case_id
        LEFT JOIN (SELECT case_id, cc.name
                    FROM us_courts_staging.cases_to_classifications c2c
                    JOIN us_courts_staging.case_classifications cc on c2c.case_classification_id=cc.category_id and level=4) c4 on c4.case_id =c2c.case_id;





