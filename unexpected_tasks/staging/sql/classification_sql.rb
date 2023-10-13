def type
  <<~SQL
    INSERT IGNORE INTO cases_to_classifications(case_id, case_classification_id)
    SELECT ca.id, cl.category_id 
    FROM cases AS ca 
      JOIN case_classifications AS cl 
        ON cl.name = ca.type;
  SQL
end

def category
  <<~SQL
    INSERT IGNORE INTO cases_to_classifications(case_id, case_classification_id)
    SELECT ca.id, cl.category_id 
    FROM cases AS ca 
      JOIN case_classifications AS cl 
        ON cl.name = ca.category;
  SQL
end

def subcategory
  <<~SQL
    INSERT IGNORE INTO cases_to_classifications(case_id, case_classification_id)
    SELECT ca.id, cl.category_id 
    FROM cases AS ca 
      JOIN case_classifications AS cl 
        ON cl.name = ca.subcategory;
  SQL
end

def additional
  <<~SQL
    INSERT IGNORE INTO cases_to_classifications(case_id, case_classification_id)
    SELECT ca.id, cl.category_id 
    FROM cases AS ca 
      JOIN case_classifications AS cl 
        ON cl.name = ca.additional_subcategory;
  SQL
end