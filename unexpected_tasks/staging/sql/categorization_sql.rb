def raw_types_from_cases
  <<~SQL
    SELECT DISTINCT raw_type 
    FROM cases 
    WHERE raw_type IS NOT NULL 
      AND type IS NULL 
      AND raw_type NOT IN (SELECT raw_type 
                           FROM us_courts_analysis.us_case_keyword_to_unique_raw_type_category);
  SQL
end

def descriptions_from_cases
  <<~SQL
    SELECT DISTINCT description
    FROM cases
    WHERE description IS NOT NULL
      AND type IS NULL
      AND description NOT IN (SELECT description
                              FROM us_courts_analysis.us_case_keyword_to_unique_description_category);
  SQL
end