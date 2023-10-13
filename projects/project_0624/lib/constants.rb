TEMP = "/home/hamster/Hamster/projects/project_0624/files" # Place the downloaded files here 
DOWNLOADS_PAGE_URL = "https://download.gosa.ga.gov/"
MAIN_FILE_NAME = "DOWNLOAD_PAGE"
PROJECT_STORAGE_DIR = "/home/hamster/HarvestStorehouse/project_0624/store"

SUB_DIRECTORIES =[
  {
    "table_name": "ga_enrollment_by_grade",
    "title": "Enrollment by Grade Level"
  },
  {
    "table_name": "ga_enrollment_by_subgroup",
    "title": "Enrollment by Subgroup Programs"
  },
  {
    "table_name": "ga_assessment_eoc_by_grade",
    "title": "Georgia Milestones End-of-Course (EOC) Assessment (by grade)"
  },
  {
    "table_name": "ga_assessment_eoc_by_subgroup",
    "title": "Georgia Milestones End-of-Course (EOC) Assessment"
  },
  {
    "table_name": "ga_assessment_eog_by_grade",
    "title": "Georgia Milestones End-of-Grade (EOG) Assessment (by grade)"
  },
  {
    "table_name": "ga_assessment_eog_by_subgroup",
    "title": "Georgia Milestones End-of-Grade (EOG) Assessment"
  },
  {
    "table_name": "ga_graduation_4_year_cohort",
    "title": "Graduation Rate (4-Year Cohort)"
  },
  {
    "table_name": "ga_graduation_5_year_cohort",
    "title": "Graduation Rate (5-Year Cohort)"
  },
  {
    "table_name": "ga_revenue_expenditure",
    "title": "Revenues and Expenditures"
  },
  {
    "table_name": "ga_salaries_benefits",
    "title": "Salaries and Benefits"
  },
  {
    "table_name": "ga_graduation_hope",
    "title": "HOPE Eligible Graduates"
  }
]

URLS_TO_SKIP = {
  "ga_enrollment_by_grade" => [],
  "ga_enrollment_by_subgroup" => [
    "https://download.gosa.ga.gov/2006/Exports/Demographics.csv", 
  ],
  "ga_assessment_eoc_by_grade" => [],
  "ga_assessment_eoc_by_subgroup" => [],
  "ga_assessment_eog_by_grade" => [],
  "ga_assessment_eog_by_subgroup" => [],
  "ga_salaries_benefits" => [],
  "ga_revenue_expenditure" => [],
  "ga_graduation_4_year_cohort" => [
    "https://download.gosa.ga.gov/2005/Exports/Graduation%20Rate.csv",
    "https://download.gosa.ga.gov/2006/Exports/Graduation%20Rate.csv",
  ],
  "ga_graduation_5_year_cohort" => [],
  "ga_graduation_hope" => [
    "https://download.gosa.ga.gov/2005/Exports/Hope.csv", 
  ]
}