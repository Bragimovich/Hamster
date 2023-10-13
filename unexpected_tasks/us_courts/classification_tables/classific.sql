INSERT IGNORE INTO cases_to_classifications (case_id,case_classification_id)
SELECT c.id, cc.category_id from cases c
                                     join case_classifications cc on cc.name = c.additional_subcategory