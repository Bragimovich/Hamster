class Parser < Hamster::Harvester

    def initialize
       super     
    end

    def get_section_urls(page_content, section_title)
        links_extractor(page_content, section_title)
    end

    def parse_ga_enrollment_by_grade(headers, record , general_id, url)
        enrollment_count_index = [headers.find_index("ENROLLMENT_COUNT"), headers.find_index("Enrollment_Count")].compact.first
        {   
            general_id: general_id,
            school_year: fix_year_field(record[ headers.find_index("LONG_SCHOOL_YEAR") ]),
            grade: record[ headers.find_index("GRADE_LEVEL") ],
            enrollment_period: record[ headers.find_index("ENROLLMENT_PERIOD") ],
            count: record[ enrollment_count_index ],
            data_source_url: url,
        }
    end

    def parse_ga_enrollment_by_subgroup(headers, record, general_id, url)
        if [
                "https://download.gosa.ga.gov/2004/Exports/demo.csv",
                "https://download.gosa.ga.gov/2005/Exports/Demo%20-%20Updated%2001-02-2007.xls",
                "https://download.gosa.ga.gov/2007/Exports/Demographics.xls",
                "https://download.gosa.ga.gov/2008/Exports/Demographics.xls",
                "https://download.gosa.ga.gov/2009/Exports/Demographics.xls",
                "https://download.gosa.ga.gov/2010/Exports/Demo.xls"
            ].include? url
            url_year = {
                "https://download.gosa.ga.gov/2004/Exports/demo.csv" => '2003-2004',
                "https://download.gosa.ga.gov/2005/Exports/Demo%20-%20Updated%2001-02-2007.xls" => '2004-2005',
                "https://download.gosa.ga.gov/2007/Exports/Demographics.xls" => '2006-2007',
                "https://download.gosa.ga.gov/2008/Exports/Demographics.xls" => '2007-2008',
                "https://download.gosa.ga.gov/2009/Exports/Demographics.xls" => '2008-2009',
                "https://download.gosa.ga.gov/2010/Exports/Demo.xls" => '2009-2010',
            }
            subgroups = [        
                'Asian',
                'Black',
                'Hispanic',
                'Native',
                'Multiracial',
                'White',
                'LEP',
                'ED',
                'SWD',
            ]
            return subgroups.map.with_index{ |item, index| {
                general_id: general_id,
                school_year: url_year[url],
                subgroup: item,
                percent: record[6+index],
                count: nil,
                data_source_url: url,
                }    
            }
        elsif [
            "https://download.gosa.ga.gov/2011/Enrollment_by_Subgroups_Programs_2011_MAR_23_2020.csv", 
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2012.xlsx", 
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2013.csv", 
            "http://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2014_Jan_15th_2015.csv", 
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2015_DEC_1st_2016.csv", 
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2016_DEC_1st_2016.csv", 
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2017_DEC_1st_2017.csv", 
            "https://download.gosa.ga.gov/2018/Enrollment_by_Subgroups_Programs_2018_DEC_10th_2018.csv", 
            "https://download.gosa.ga.gov/2019/Enrollment_by_Subgroups_Programs_2019_Dec2nd_2019.csv", 
            "https://download.gosa.ga.gov/2020/Enrollment_by_Subgroups_Programs_2020_Dec112020.csv", 
            "https://download.gosa.ga.gov/2021/Enrollment_by_Subgroups_Programs_2021_Dec062021.csv", 
            "https://download.gosa.ga.gov/2022/Enrollment_by_Subgroups_Programs_2022_Dec072022.csv"
        ].include? url
            all_groups = {
                "ENROLL_PERCENT_ASIAN"=> { subgroup_tag: "Asian", count_field: nil },
                "ENROLL_PERCENT_NATIVE"=> { subgroup_tag: "Native", count_field: nil },
                "ENROLL_PERCENT_BLACK"=> { subgroup_tag: "Black", count_field: nil },
                "ENROLL_PERCENT_HISPANIC"=> { subgroup_tag: "Hispanic", count_field: nil },
                "ENROLL_PERCENT_MULTIRACIAL"=> { subgroup_tag: "Multiracial", count_field: nil },
                "ENROLL_PERCENT_WHITE"=> { subgroup_tag: "White", count_field: nil },
                "ENROLL_PERCENT_MIGRANT"=> { subgroup_tag: "Migrant", count_field: nil },
                "ENROLL_PERCENT_ED"=> { subgroup_tag: "ED", count_field: nil },
                "ENROLL_PERCENT_SWD"=> { subgroup_tag: "SWD", count_field: nil },
                "ENROLL_PERCENT_LEP"=> { subgroup_tag: "LEP", count_field: nil },
                "ENROLL_PCT_REMEDIAL_GR_6_8"=> { subgroup_tag: "REMEDIAL_GR_6_8", count_field: "ENROLL_COUNT_REMEDIAL_GR_6_8" },
                "ENROLL_PERCENT_EIP_K_5"=> { subgroup_tag: "EIP_K_5", count_field: "ENROLL_COUNT_EIP_K_5" },
                "ENROLL_PCT_REMEEDIAL_GR_9_12"=> { subgroup_tag: "REMEDIAL_GR_9_12", count_field: "ENROLL_COUNT_REMEDIAL_GR_9_12" },
                "ENROLL_PCT_SPECIAL_ED_K12"=> { subgroup_tag: "SPECIAL_ED_K12", count_field: "ENROLL_COUNT_SPECIAL_ED_K12" },
                "ENROLL_PCT_ESOL"=> { subgroup_tag: "ESOL", count_field: "ENROLL_COUNT_ESOL" },
                "ENROLL_PCT_SPECIAL_ED_PK"=> { subgroup_tag: "SPECIAL_ED_PK", count_field: "ENROLL_COUNT_SPECIAL_ED_PK" },
                "ENROLL_PCT_VOCATION_9_12"=> { subgroup_tag: "VOCATION_9_12", count_field: "ENROLL_COUNT_VOCATION_9_12" },
                "ENROLL_PCT_ALT_PROGRAMS"=> { subgroup_tag: "ALT_PROGRAMS", count_field: "ENROLL_COUNT_ALT_PROGRAMS" },
                "ENROLL_PCT_GIFTED"=> { subgroup_tag: "GIFTED", count_field: "ENROLL_COUNT_GIFTED" },
                "ENROLL_PERCENT_MALE"=> { subgroup_tag: "MALE", count_field: nil },
                "ENROLL_PERCENT_FEMALE"=> { subgroup_tag: "FEMALE", count_field: nil }
            }
            records = []

            all_groups.keys.each{ |item| 
                if headers.include? item.to_s
                    count_field = all_groups[item][:count_field]
                    records.append({
                        general_id: general_id,
                        school_year: fix_year_field(record[ headers.find_index("LONG_SCHOOL_YEAR") ]),
                        subgroup: all_groups[item][:subgroup_tag],
                        percent: record[headers.find_index(item)],
                        count: count_field ? record[ headers.find_index(count_field) ] : nil,
                        data_source_url: url,
                    })
                end                
            }
            records
        end
    end

    def parse_ga_assessment_eoc_by_grade(headers, record, general_id, url)
        # HEADERS FOR  ga_assessment_eoc_by_grade are ["LONG_SCHOOL_YEAR", "SCHOOL_DISTRCT_CD", "SCHOOL_DSTRCT_NM", "INSTN_NUMBER", "INSTN_NAME", "ACDMC_LVL", "SUBGROUP_NAME", "TEST_CMPNT_TYP_NM", "NUM_TESTED_CNT", "BEGIN_CNT", "DEVELOPING_CNT", "PROFICIENT_CNT", "DISTINGUISHED_CNT", "BEGIN_PCT", "DEVELOPING_PCT", "PROFICIENT_PCT", "DISTINGUISHED_PCT"]
        {
            general_id: general_id,
            school_year: fix_year_field(record[headers.find_index("LONG_SCHOOL_YEAR")]),
            grade: record[headers.find_index("ACDMC_LVL")],
            subgroup: record[headers.find_index("SUBGROUP_NAME")],
            test: record[headers.find_index("TEST_CMPNT_TYP_NM")],
            tested_count: record[headers.find_index("NUM_TESTED_CNT")],
            begin_count: record[headers.find_index("BEGIN_CNT")],
            begin_percent: record[headers.find_index("BEGIN_PCT")],
            developing_count: record[headers.find_index("DEVELOPING_CNT")],
            developing_percent: record[headers.find_index("DEVELOPING_PCT")],
            proficient_count: record[headers.find_index("PROFICIENT_CNT")],
            proficient_percent: record[headers.find_index("PROFICIENT_PCT")],
            distinguished_count: record[headers.find_index("DISTINGUISHED_CNT")],
            distinguished_percent: record[headers.find_index("DISTINGUISHED_PCT")],   
            data_source_url: url 
        }
    end

    def parse_ga_assessment_eoc_by_subgroup(headers, record, general_id, url)
        # Collected unique values from all files
        subgroup_mapping = {
            "All Students" => "All Students",
            "Male" => "Male",
            "Female" => "Female",
            "Black or African American" => "Black",
            "White" => "White",
            "Hispanic" => "Hispanic",
            "Students with Disabilities" => "SWD",
            "Students without Disabilities" => "SWOD",
            "Limited English Proficient" => "LEP",
            "Not Limited English Proficient" => "NLEP",
            "Economically Disadvantaged" => "ED",
            "Not Economically Disadvantaged" => "NED",
            "Migrant" => "Migrant",
            "Non-Migrant" => "Non Migrant",
            "Two or More Races" => "Multiracial",
            "Asian" => "Asian",
            "American Indian or Alaskan Native" => "Native",
            "Native Hawaiian or Other Pacific Islander" => "Other Native",
            "Homeless" => "Homeless",
            "Active Duty" => "Active Duty",
            "Foster" => "Foster",
            "Military Connected" => "Military Connected",
            "Foster Care" => "Foster Care",
            
        }
        {
            general_id: general_id,
            school_year: fix_year_field(record[headers.find_index("LONG_SCHOOL_YEAR")]),
            subgroup: subgroup_mapping[record[headers.find_index("SUBGROUP_NAME")]],
            test: record[headers.find_index("TEST_CMPNT_TYP_NM")],
            tested_count: record[headers.find_index("NUM_TESTED_CNT")],
            begin_count: record[headers.find_index("BEGIN_CNT")],
            developing_count: record[headers.find_index("DEVELOPING_CNT")],
            proficient_count: record[headers.find_index("PROFICIENT_CNT")],
            distinguished_count: record[headers.find_index("DISTINGUISHED_CNT")],
            begin_percent: record[headers.find_index("BEGIN_PCT")],
            developing_percent: record[headers.find_index("DEVELOPING_PCT")],
            proficient_percent: record[headers.find_index("PROFICIENT_PCT")],
            distinguished_percent: record[headers.find_index("DISTINGUISHED_PCT")],   
            data_source_url: url
        }
    end

    def parse_ga_assessment_eog_by_grade(headers, record, general_id, url)
        # HEADERS FOR  ga_assessment_eog_by_grade are ["LONG_SCHOOL_YEAR", "SCHOOL_DISTRCT_CD", "SCHOOL_DSTRCT_NM", "INSTN_NUMBER", "INSTN_NAME", "ACDMC_LVL", "SUBGROUP_NAME", "TEST_CMPNT_TYP_NM", "NUM_TESTED_CNT", "BEGIN_CNT", "DEVELOPING_CNT", "PROFICIENT_CNT", "DISTINGUISHED_CNT", "BEGIN_PCT", "DEVELOPING_PCT", "PROFICIENT_PCT", "DISTINGUISHED_PCT"]
        {
            general_id: general_id,
            school_year: fix_year_field(record[headers.find_index("LONG_SCHOOL_YEAR")]),
            grade: record[headers.find_index("ACDMC_LVL")],
            subgroup: record[headers.find_index("SUBGROUP_NAME")],
            test: record[headers.find_index("TEST_CMPNT_TYP_NM")],
            tested_count: record[headers.find_index("NUM_TESTED_CNT")],
            begin_count: record[headers.find_index("BEGIN_CNT")],
            developing_count: record[headers.find_index("DEVELOPING_CNT")],
            proficient_count: record[headers.find_index("PROFICIENT_CNT")],
            distinguished_count: record[headers.find_index("DISTINGUISHED_CNT")],
            begin_percent: record[headers.find_index("BEGIN_PCT")],
            developing_percent: record[headers.find_index("DEVELOPING_PCT")],
            proficient_percent: record[headers.find_index("PROFICIENT_PCT")],
            distinguished_percent: record[headers.find_index("DISTINGUISHED_PCT")],   
            data_source_url: url 
        }
    end

    def parse_ga_assessment_eog_by_subgroup(headers, record, general_id, url)
        # Collected unique values from all files
        subgroup_mapping ={
            "All Students"=> "All Students",
            "Male"=> "Male",
            "Female"=> "Female",
            "Black or African American"=> "Black",
            "White"=> "White",
            "Two or More Races"=> "Multiracial",
            "Hispanic"=> "Hispanic",
            "Students with Disabilities"=> "SWD",
            "Students without Disabilities"=> "SWOD",
            "Limited English Proficient"=> "LEP",
            "Not Limited English Proficient"=> "NLEP",
            "Economically Disadvantaged"=> "ED",
            "Not Economically Disadvantaged"=> "NED",
            "Migrant"=> "Migrant",
            "Non-Migrant"=> "Non Migrant",
            "Native Hawaiian or Other Pacific Islander"=> "Other Native",
            "Asian"=> "Asian",
            "American Indian or Alaskan Native"=> "Native",
            "Homeless"=> "Homeless",
            "Foster"=> "Foster",
            "Active Duty"=> "Active Duty",
            "Foster Care"=> "Foster Care",
            "Military Connected"=> "Military Connected",
        }
        
        {
            general_id: general_id,
            school_year: fix_year_field(record[headers.find_index("LONG_SCHOOL_YEAR")]),
            subgroup: subgroup_mapping[record[headers.find_index("SUBGROUP_NAME")]],
            test: record[headers.find_index("TEST_CMPNT_TYP_NM")],
            tested_count: record[headers.find_index("NUM_TESTED_CNT")],
            begin_count: record[headers.find_index("BEGIN_CNT")],
            developing_count: record[headers.find_index("DEVELOPING_CNT")],
            proficient_count: record[headers.find_index("PROFICIENT_CNT")],
            distinguished_count: record[headers.find_index("DISTINGUISHED_CNT")],
            begin_percent: record[headers.find_index("BEGIN_PCT")],
            developing_percent: record[headers.find_index("DEVELOPING_PCT")],
            proficient_percent: record[headers.find_index("PROFICIENT_PCT")],
            distinguished_percent: record[headers.find_index("DISTINGUISHED_PCT")],   
            data_source_url: url
        }
    end

    def parse_ga_graduation_4_year_cohort(headers, record, general_id, url)
        url_year = {
            "https://download.gosa.ga.gov/2004/Exports/Graduation%20Rate.csv" => "2003-2004",
            "https://download.gosa.ga.gov/2007/Exports/Graduation%20Rate.xls" => "2006-2007",
            "https://download.gosa.ga.gov/2008/Exports/Graduation%20Rate.xls" => "2007-2008",
            "https://download.gosa.ga.gov/2009/Exports/GradRate.xls" => "2008-2009",
            "https://download.gosa.ga.gov/2010/Exports/Grad%20Rate.xls" => "2009-2010",
            "https://download.gosa.ga.gov/2011/Graduation_Rate_2011_MAR_23_2020.csv" => "2010-2011",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related _files/site_page/Graduation_Rate_2012_4yr.csv" => "2011-2012",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2013_DEC_1st_2016.csv" => "2012-2013",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2014_DEC_1st_2016.csv" => "2013-2014",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2015_DEC_1st_2016.csv" => "2014-2015",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2016_DEC_1st_2016.csv" => "2015-2016",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2017_DEC_1st_2017.csv" => "2016-2017",
            "https://download.gosa.ga.gov/2018/Graduation_Rate_2018_JAN_24th_2019.csv" => "2017-2018",
            "https://download.gosa.ga.gov/2019/Graduation_Rate_2019_Dec2nd_2019.csv" => "2018-2019",
            "https://download.gosa.ga.gov/2020/Graduation_Rate_2020_Dec112020.csv" => "2019-2020",
            "https://download.gosa.ga.gov/2021/Graduation_Rate_2021_Dec062021.csv" => "2020-2021",
            "https://download.gosa.ga.gov/2022/Graduation_Rate_2022_Dec082022.csv" => "2021-2022",
        }
        if [
            "https://download.gosa.ga.gov/2004/Exports/Graduation%20Rate.csv",
            "https://download.gosa.ga.gov/2007/Exports/Graduation%20Rate.xls",
            "https://download.gosa.ga.gov/2008/Exports/Graduation%20Rate.xls",
            "https://download.gosa.ga.gov/2009/Exports/GradRate.xls",
            "https://download.gosa.ga.gov/2010/Exports/Grad%20Rate.xls",
        ].include? url 
            records  = []
            subgroups = [
                "ALL Students",
                "Asian",
                "Black",
                "Hispanic",
                "Native",
                "White",
                "Multiracial",
                "Male",
                "Female",
                "SWD",
                "SWOD",
                "LEP",
                "ED",
                "NED",
                "Migrant",
            ]
            
            subgroups.each_with_index{ |subgroup, index|
                total_count_index = 2 + (index*3) + 2
                program_total_index = 2 + (index*3) + 1
                program_percent_index = 2 + (index*3)

                records << { 
                    general_id: general_id,
                    school_year: url_year[url],
                    subgroup: subgroup,
                    program_total:  record[program_total_index],
                    program_percent:  record[program_percent_index],
                    total_count:  record[total_count_index],
                    data_source_url: url,
                }
            }

            return records
        elsif [
            "https://download.gosa.ga.gov/2011/Graduation_Rate_2011_MAR_23_2020.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2012_4yr.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2013_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2014_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2015_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2016_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2017_DEC_1st_2017.csv",
            "https://download.gosa.ga.gov/2018/Graduation_Rate_2018_JAN_24th_2019.csv",
            "https://download.gosa.ga.gov/2019/Graduation_Rate_2019_Dec2nd_2019.csv",
            "https://download.gosa.ga.gov/2020/Graduation_Rate_2020_Dec112020.csv",
            "https://download.gosa.ga.gov/2021/Graduation_Rate_2021_Dec062021.csv",
            "https://download.gosa.ga.gov/2022/Graduation_Rate_2022_Dec082022.csv"
        ].include? url
            # Collected unique values from all files
            subgroup_mapping = {
                "Grad Rate -ALL Students" => "All Students",
                "Grad Rate -American Indian/Alaskan" => "All",
                "Grad Rate -Asian/Pacific Islander" => "Asian",
                "Grad Rate -Black" => "Black",
                "Grad Rate -Economically Disadvantaged" => "ED",
                "Grad Rate -Female" => "Female",
                "Grad Rate -Hispanic" => "Hispanic",
                "Grad Rate -Limited English Proficient" => "LEP",
                "Grad Rate -Male" => "Male",
                "Grad Rate -Migrant" => "Migrant",
                "Grad Rate -Multi-Racial" => "Multiracial",
                "Grad Rate -Not Economically Disadvantaged" => "NED",
                "Grad Rate -Students With Disability" => "SWD",
                "Grad Rate -Students Without Disability" => "SWOD",
                "Grad Rate -White" => "White",
                "Grad Rate -Active Duty" => "Active Duty",
                "Grad Rate -Foster" => "Foster",
                "Grad Rate -Homeless" => "Homeless"
            }
            total_count_index = headers.find_index("TOTAL_COUNT")
            return [
                {
                    general_id: general_id,
                    school_year: url_year[url],
                    subgroup: subgroup_mapping[ headers.find_index("LABEL_LVL_1_DESC") ],
                    program_total:  record[ headers.find_index("PROGRAM_TOTAL") ],
                    program_percent:  record[ headers.find_index("PROGRAM_PERCENT") ],
                    total_count:  total_count_index ? record[ total_count_index ] : nil,
                    data_source_url: url,
                }
            ]
        end
    end

    def parse_ga_graduation_5_year_cohort(headers, record, general_id, url)
        # Collected unique values from all files
        subgroup_mapping = {
            "5 Yr Grad Rate -ALL Students" => "All Students",
            "5 Yr Grad Rate -American Indian/Alaskan" => "Native",
            "5 Yr Grad Rate -Asian/Pacific Islander" => "Asian",
            "5 Yr Grad Rate -Black" => "Black",
            "5 Yr Grad Rate -Economically Disadvantaged" => "ED",
            "5 Yr Grad Rate -Female" => "Female",
            "5 Yr Grad Rate -Hispanic" => "Hispanic",
            "5 Yr Grad Rate -Homeless" => "Homeless",
            "5 Yr Grad Rate -Limited English Proficient" => "LEP",
            "5 Yr Grad Rate -Male" => "Male",
            "5 Yr Grad Rate -Migrant" => "Migrant",
            "5 Yr Grad Rate -Multi-Racial" => "Multiracial",
            "5 Yr Grad Rate -Not Economically Disadvantaged" => "NED",
            "5 Yr Grad Rate -Students With Disability" => "SWD",
            "5 Yr Grad Rate -Students Without Disability" => "SWOD",
            "5 Yr Grad Rate -White" => "White",
            "5 Yr Grad Rate -Active Duty" => "Active Duty",
            "5 Yr Grad Rate -Foster" => "Foster",
        }
        return [
            {
                general_id: general_id,
                school_year: fix_year_field( record[ headers.find_index("LONG_SCHOOL_YEAR") ] ),
                subgroup: subgroup_mapping[ headers.find_index("LABEL_LVL_1_DESC") ],
                program_total:  record[ headers.find_index("PROGRAM_TOTAL") ],
                program_percent:  record[ headers.find_index("PROGRAM_PERCENT") ],
                total_count:  record[ headers.find_index("TOTAL_COUNT") ],
                data_source_url: url,
            }
        ]
    end

    def parse_ga_salaries_benefits(headers, record, general_id, url)
        # Headers for ga_revenue_expenditure ["LONG_SCHOOL_YEAR", "SCHOOL_DSTRCT_CD", "SCHOOL_DSTRCT_NM", "INSTN_NUMBER", "INSTN_NAME", "CATEGORY", "SALARIES", "BENEFITS", "SALARIES_AND_BENEFITS", "% Rev- GF/Title/Lottery", "% Rev- Total K-12", "% Exp- GF/Title/Lottery", "% Exp-Total K-12"]
        {
            general_id: general_id,
            school_year: fix_year_field(record[headers.find_index("LONG_SCHOOL_YEAR")]),
            category: record[headers.find_index("CATEGORY")],
            salaries: record[headers.find_index("SALARIES")],
            benefits: record[headers.find_index("BENEFITS")],
            salaries_and_benefits: record[headers.find_index("SALARIES_AND_BENEFITS")],
            rev_gf_title_lottery_percent: record[headers.find_index("% Rev- GF/Title/Lottery")],
            rev_total_k_12_percent: record[headers.find_index("% Rev- Total K-12")],
            exp_gf_title_lottery_percent: record[headers.find_index("% Exp- GF/Title/Lottery")],
            exp_total_k_12_percent: record[headers.find_index("% Exp-Total K-12")],
            data_source_url: url,
        }
    end

    def parse_ga_revenue_expenditure(headers, record, general_id, url)
        # Headers for ga_revenue_expenditure ["SCHOOL_YEAR", "DISTRICT_CODE", "DISTRICT_NAME", "SCHOOL_CODE", "SCHOOL_NAME", "Revenues/Expenditures", "Description", "REV_EXP_VALUE", "Dollars per FTE"]
        {
            general_id: general_id,
            school_year: fix_year_field(record[headers.find_index("SCHOOL_YEAR")]),
            revenue_expenditures: record[headers.find_index("Revenues/Expenditures")],
            description: record[headers.find_index("Description")],
            rev_exp_value: record[headers.find_index("REV_EXP_VALUE")],
            dollars_per_fte: record[headers.find_index("Dollars per FTE")],
            data_source_url: url,
        }
    end

    def parse_ga_graduation_hope(headers, record, general_id, url)
        url_year ={
            "https://download.gosa.ga.gov/2004/Exports/hope.csv" => "2003-2004",
            "https://download.gosa.ga.gov/2006/Exports/Hope.xls" => "2005-2006",
            "https://download.gosa.ga.gov/2007/Exports/Hope.xls" => "2006-2007",
            "https://download.gosa.ga.gov/2010/Exports/Hope.xls" => "2009-2010",
        }

        if [
            "https://download.gosa.ga.gov/2004/Exports/hope.csv",
            "https://download.gosa.ga.gov/2006/Exports/Hope.xls",
            "https://download.gosa.ga.gov/2007/Exports/Hope.xls",
            "https://download.gosa.ga.gov/2010/Exports/Hope.xls",
        ].include? url
            return {
                general_id: general_id,
                school_year: url_year[url],
                number_of_graduates: record[2].to_i,
                hope_eligible: record[3].to_i,
                hope_eligible_percent: record[4],
                data_source_url: url
            }
        elsif url == "https://download.gosa.ga.gov/2008/Exports/HOPE_Eligibility_2008.xls"
            if record.length == 7
                return {
                    general_id: general_id,
                    school_year: '2007-2008',
                    number_of_graduates: record[4].to_i,
                    hope_eligible: record[5].to_i,
                    hope_eligible_percent: record[6],
                    data_source_url: url
                }
            elsif record.length == 9
                return {
                    general_id: general_id,
                    school_year: '2007-2008',
                    number_of_graduates: record[6].to_i,
                    hope_eligible: record[7].to_i,
                    hope_eligible_percent: record[8],
                    data_source_url: url
                }
            else
                return {
                    general_id: general_id,
                    school_year: '2007-2008',
                    number_of_graduates: record[8].to_i,
                    hope_eligible: record[9].to_i,
                    hope_eligible_percent: record[10],
                    data_source_url: url
                }
            end
        elsif [
            "https://download.gosa.ga.gov/2010/Exports/Hope.xls", 
            "https://download.gosa.ga.gov/2011/Hope_Eligible_2011_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2012/Hope_Eligible_2012_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2013/Hope_Eligible_2013_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2014/Hope_Eligible_2014_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2015/Hope_Eligible_2015_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2016/Hope_Eligible_2016_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2017/Hope_Eligible_2017_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2018/Hope_Eligible_2018_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2019/Hope_Eligible_2019_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2020/HOPE_ELIGIBILITY_2020_JUN_21_2021.csv", 
            "https://download.gosa.ga.gov/2021/Hope_Eligibility_2021_Dec062021.csv", 
            "https://download.gosa.ga.gov/2022/Hope_Eligibility_2022_Dec072022.csv"
        ].include? url
            return {
                general_id: general_id,
                school_year: fix_year_field( record[ headers.find_index("LONG_SCHOOL_YEAR") ] ),
                number_of_graduates: record[5].to_i,
                hope_eligible: record[6].to_i,
                hope_eligible_percent: record[7],
                data_source_url: url
            }
        end
    end

    #############################################

### To get general_info id 
    def get_ids_for_general_info(section_name, item, headers, url)
        if section_name == "ga_enrollment_by_grade"
            return { type: item[1], district_number: item[2], school_number: item[4] }
        elsif section_name == "ga_enrollment_by_subgroup"
            return get_ids_for_general_info_for_enrollment_by_subgroup(url, item)
        elsif [
                "ga_assessment_eoc_by_grade", 
                "ga_assessment_eoc_by_subgroup", 
                "ga_assessment_eog_by_grade",
                "ga_assessment_eog_by_subgroup",
                "ga_salaries_benefits",
                "ga_revenue_expenditure"
            ].include? section_name
            if item[1] == "ALL" and item[3] =="ALL"
                return { type: "State", district_number: nil, school_number: nil }
            elsif item[3] == "ALL" 
                return { type: "District", district_number: item[1], school_number: nil }
            else
                return { type: "School", district_number: item[1], school_number: item[3] }
            end
        elsif section_name == "ga_graduation_4_year_cohort"
            return get_ids_for_general_info_for_graduation_4_year_cohort(url, item)
        elsif section_name == "ga_graduation_5_year_cohort"
            return get_ids_for_general_info_for_graduation_5_year_cohort(url, item)
        elsif section_name == "ga_graduation_hope"
            return get_ids_for_general_info_for_graduation_hope(url, item)
        else 
            @logger.info "Bad section name!".red
        end
    end

    def get_ids_for_general_info_for_enrollment_by_subgroup(url, item)
        if [
            "https://download.gosa.ga.gov/2004/Exports/demo.csv",
            "https://download.gosa.ga.gov/2005/Exports/Demo%20-%20Updated%2001-02-2007.xls",
            "https://download.gosa.ga.gov/2007/Exports/Demographics.xls", 
            "https://download.gosa.ga.gov/2008/Exports/Demographics.xls", 
            "https://download.gosa.ga.gov/2009/Exports/Demographics.xls", 
            "https://download.gosa.ga.gov/2010/Exports/Demo.xls", 
        ].include? url 
            i1 = item[0].split(":")
            d_id = i1[0]
            s_id = i1[1]
            if d_id == "ALL" and s_id =="ALL"
                return { type: "State", district_number: nil, school_number: nil }
            elsif s_id == "ALL" 
                return { type: "District", district_number: d_id, school_number: nil }
            else
                return { type: "School", district_number: d_id, school_number: s_id }
            end
        elsif [
            "https://download.gosa.ga.gov/2011/Enrollment_by_Subgroups_Programs_2011_MAR_23_2020.csv", 
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2012.xlsx", 
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2013.csv", 
            "http://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2014_Jan_15th_2015.csv", 
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2015_DEC_1st_2016.csv", 
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2016_DEC_1st_2016.csv", 
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2017_DEC_1st_2017.csv", 
            "https://download.gosa.ga.gov/2018/Enrollment_by_Subgroups_Programs_2018_DEC_10th_2018.csv", 
            "https://download.gosa.ga.gov/2019/Enrollment_by_Subgroups_Programs_2019_Dec2nd_2019.csv", 
            "https://download.gosa.ga.gov/2020/Enrollment_by_Subgroups_Programs_2020_Dec112020.csv", 
            "https://download.gosa.ga.gov/2021/Enrollment_by_Subgroups_Programs_2021_Dec062021.csv", 
            "https://download.gosa.ga.gov/2022/Enrollment_by_Subgroups_Programs_2022_Dec072022.csv"
        ].include? url
            s_id = item[1]
            d_id = item[2]
            if d_id == "ALL" and s_id =="ALL"
                return { type: "State", district_number: nil, school_number: nil }
            elsif s_id == "ALL" 
                return { type: "District", district_number: d_id, school_number: nil }
            else
                return { type: "School", district_number: d_id, school_number: s_id }
            end
        end
    end

    def get_ids_for_general_info_for_graduation_4_year_cohort(url,item)
        if [
            "https://download.gosa.ga.gov/2004/Exports/Graduation%20Rate.csv",
            "https://download.gosa.ga.gov/2007/Exports/Graduation%20Rate.xls",
            "https://download.gosa.ga.gov/2008/Exports/Graduation%20Rate.xls",
            "https://download.gosa.ga.gov/2009/Exports/GradRate.xls",
            "https://download.gosa.ga.gov/2010/Exports/Grad%20Rate.xls",
        ].include? url 
            i1 = item[0].split(":")
            d_id = i1[0]
            s_id = i1[1]
            if d_id == "ALL" and s_id =="ALL"
                return { type: "State", district_number: nil, school_number: nil }
            elsif s_id == "ALL" 
                return { type: "District", district_number: d_id, school_number: nil }
            else
                return { type: "School", district_number: d_id, school_number: s_id }
            end
        elsif [
            "https://download.gosa.ga.gov/2011/Graduation_Rate_2011_MAR_23_2020.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2012_4yr.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2013_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2014_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2015_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2016_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2017_DEC_1st_2017.csv",
            "https://download.gosa.ga.gov/2018/Graduation_Rate_2018_JAN_24th_2019.csv",
            "https://download.gosa.ga.gov/2019/Graduation_Rate_2019_Dec2nd_2019.csv",
            "https://download.gosa.ga.gov/2020/Graduation_Rate_2020_Dec112020.csv",
            "https://download.gosa.ga.gov/2021/Graduation_Rate_2021_Dec062021.csv",
            "https://download.gosa.ga.gov/2022/Graduation_Rate_2022_Dec082022.csv"
        ].include? url
            s_id = item[4]
            d_id = item[2]
            if d_id == "ALL" and s_id =="ALL"
                return { type: "State", district_number: nil, school_number: nil }
            elsif s_id == "ALL" 
                return { type: "District", district_number: d_id, school_number: nil }
            else
                return { type: "School", district_number: d_id, school_number: s_id }
            end
        end
    end

    def get_ids_for_general_info_for_graduation_5_year_cohort(url,item)
        s_id = item[4]
        d_id = item[2]
        if d_id == "ALL" and s_id =="ALL"
            return { type: "State", district_number: nil, school_number: nil }
        elsif s_id == "ALL" 
            return { type: "District", district_number: d_id, school_number: nil }
        else
            return { type: "School", district_number: d_id, school_number: s_id }
        end
    end

    def get_ids_for_general_info_for_graduation_hope(url,item)
        if [
            "https://download.gosa.ga.gov/2004/Exports/hope.csv",
            "https://download.gosa.ga.gov/2006/Exports/Hope.xls",
            "https://download.gosa.ga.gov/2007/Exports/Hope.xls",
            "https://download.gosa.ga.gov/2010/Exports/Hope.xls",
        ].include? url
            i1 = item[0].split(":")
            d_id = i1[0]
            # We will ignore the school id which have 'x' in them.
            # It only occurs in 2004 files.
            if i1[1].include? 'x'
                s_id = nil
            else
                s_id = i1[1]                
            end

            if d_id == "ALL" and s_id =="ALL"
                return { type: "State", district_number: nil, school_number: nil }
            elsif s_id == "ALL" 
                return { type: "District", district_number: d_id, school_number: nil }
            else
                return { type: "School", district_number: d_id, school_number: s_id }
            end
        elsif url == "https://download.gosa.ga.gov/2008/Exports/HOPE_Eligibility_2008.xls"
            if item.length == 7
                return { type: "State", district_number: nil, school_number: nil }
            elsif item.length == 9
                return { type: "District", district_number: item[4], school_number: nil }
            else
                return { type: "School", district_number: item[4], school_number: item[5] }
            end
        elsif [
            "https://download.gosa.ga.gov/2010/Exports/Hope.xls", 
            "https://download.gosa.ga.gov/2011/Hope_Eligible_2011_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2012/Hope_Eligible_2012_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2013/Hope_Eligible_2013_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2014/Hope_Eligible_2014_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2015/Hope_Eligible_2015_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2016/Hope_Eligible_2016_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2017/Hope_Eligible_2017_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2018/Hope_Eligible_2018_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2019/Hope_Eligible_2019_FEB_24_2020.csv", 
            "https://download.gosa.ga.gov/2020/HOPE_ELIGIBILITY_2020_JUN_21_2021.csv", 
            "https://download.gosa.ga.gov/2021/Hope_Eligibility_2021_Dec062021.csv", 
            "https://download.gosa.ga.gov/2022/Hope_Eligibility_2022_Dec072022.csv"
        ].include? url
            s_id = item[3]
            d_id = item[1]
            if d_id == "ALL" and s_id =="ALL"
                return { type: "State", district_number: nil, school_number: nil }
            elsif s_id == "ALL" 
                return { type: "District", district_number: d_id, school_number: nil }
            else
                return { type: "School", district_number: d_id, school_number: s_id }
            end
        end
    end
### To get general_info id 

### To gather general_info 
    def get_general_info_from(section_name, item, type, url, headers)
        if section_name == "ga_enrollment_by_grade"
            if type == "District"
                return {
                    is_district: 1,
                    district_id: nil,
                    number: item[2].to_i,
                    name: item[3],
                    state:"GA",
                    data_source_url: url 
                 }
            elsif type == "School"
                return { 
                    is_district: 0,
                    district_id: item[2].to_i, # This will be replaced during insertion
                    number: item[4].to_i,
                    name: item[5],
                    state:"GA",
                    data_source_url: url 
                 }
            end
        elsif section_name == "ga_enrollment_by_subgroup"
            return get_general_info_from_enrollment_by_subgroup(url, type, item)
        elsif [
            "ga_assessment_eoc_by_grade", 
            "ga_assessment_eoc_by_subgroup", 
            "ga_assessment_eog_by_grade",
            "ga_assessment_eog_by_subgroup",
            "ga_salaries_benefits",
            "ga_revenue_expenditure"
        ].include? section_name
            if type == "District"
                return {
                    is_district: 1,
                    district_id: nil,
                    number: item[1].to_i,
                    name: item[2],
                    state:"GA",
                    data_source_url: url 
                }
            elsif type == "School"
                return {
                    is_district: 1,
                    district_id: nil,
                    number: item[3].to_i,
                    name: item[4],
                    state:"GA",
                    data_source_url: url 
                }
            end
        elsif section_name == "ga_graduation_4_year_cohort"
            return get_general_info_from_graduation_4_year_cohort(url, type, item)
        elsif section_name == "ga_graduation_5_year_cohort"
            return get_general_info_from_graduation_5_year_cohort(url, type, item)
        elsif section_name == "ga_graduation_hope"
            return get_general_info_from_graduation_hope(url, type, item)
        else
            @logger.info "Bad Record Type!".red
        end
    end

    def get_general_info_from_enrollment_by_subgroup(url, type, item)
        if [
            "https://download.gosa.ga.gov/2004/Exports/demo.csv",
            "https://download.gosa.ga.gov/2005/Exports/Demo%20-%20Updated%2001-02-2007.xls",
            "https://download.gosa.ga.gov/2007/Exports/Demographics.xls", 
            "https://download.gosa.ga.gov/2008/Exports/Demographics.xls", 
            "https://download.gosa.ga.gov/2009/Exports/Demographics.xls", 
            "https://download.gosa.ga.gov/2010/Exports/Demo.xls", 
        ].include? url 
            i1 = item[0].split(":")
            d_id = i1[0]
            s_id = i1[1]
            if type == "District" 
                return { 
                    is_district: 1,
                    district_id: nil,
                    number: d_id.to_i,
                    name: item[1],
                    state:"GA",
                    data_source_url: url 
                }
            else
                return { 
                    is_district: 0,
                    district_id: d_id, # This will be replaced during insertion
                    number: s_id.to_i,
                    name: item[2],
                    state:"GA",
                    data_source_url: url 
                }
            end
        elsif [
            "https://download.gosa.ga.gov/2011/Enrollment_by_Subgroups_Programs_2011_MAR_23_2020.csv", 
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2012.xlsx", 
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2013.csv", 
            "http://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2014_Jan_15th_2015.csv", 
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2015_DEC_1st_2016.csv", 
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2016_DEC_1st_2016.csv", 
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Enrollment_by_Subgroups_Programs_2017_DEC_1st_2017.csv", 
            "https://download.gosa.ga.gov/2018/Enrollment_by_Subgroups_Programs_2018_DEC_10th_2018.csv", 
            "https://download.gosa.ga.gov/2019/Enrollment_by_Subgroups_Programs_2019_Dec2nd_2019.csv", 
            "https://download.gosa.ga.gov/2020/Enrollment_by_Subgroups_Programs_2020_Dec112020.csv", 
            "https://download.gosa.ga.gov/2021/Enrollment_by_Subgroups_Programs_2021_Dec062021.csv", 
            "https://download.gosa.ga.gov/2022/Enrollment_by_Subgroups_Programs_2022_Dec072022.csv"
        ].include? url
            s_id = item[1]
            d_id = item[2]
            if type == "District" 
                return { 
                    is_district: 1,
                    district_id: nil,
                    number: d_id.to_i,
                    name: item[5],
                    state:"GA",
                    data_source_url: url 
                }
            else
                return { 
                    is_district: 0,
                    district_id: d_id, # This will be replaced during insertion
                    number: s_id.to_i,
                    name: item[4],
                    state:"GA",
                    data_source_url: url 
                }
            end
        end
    end

    def get_general_info_from_graduation_4_year_cohort(url, type, item)
        if [
            "https://download.gosa.ga.gov/2004/Exports/Graduation%20Rate.csv",
            "https://download.gosa.ga.gov/2007/Exports/Graduation%20Rate.xls",
            "https://download.gosa.ga.gov/2008/Exports/Graduation%20Rate.xls",
            "https://download.gosa.ga.gov/2009/Exports/GradRate.xls",
            "https://download.gosa.ga.gov/2010/Exports/Grad%20Rate.xls",
        ].include? url 
            i1 = item[0].split(":")
            d_id = i1[0]
            s_id = i1[1]
            if type == "District" 
                return { 
                    is_district: 1,
                    district_id: nil,
                    number: d_id.to_i,
                    name: item[1],
                    state:"GA",
                    data_source_url: url 
                }
            else
                return { 
                    is_district: 0,
                    district_id: d_id, # This will be replaced during insertion
                    number: s_id.to_i,
                    name: item[2],
                    state:"GA",
                    data_source_url: url 
                }
            end
        elsif [
            "https://download.gosa.ga.gov/2011/Graduation_Rate_2011_MAR_23_2020.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2012_4yr.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2013_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2014_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2015_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2016_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2017_DEC_1st_2017.csv",
            "https://download.gosa.ga.gov/2018/Graduation_Rate_2018_JAN_24th_2019.csv",
            "https://download.gosa.ga.gov/2019/Graduation_Rate_2019_Dec2nd_2019.csv",
            "https://download.gosa.ga.gov/2020/Graduation_Rate_2020_Dec112020.csv",
            "https://download.gosa.ga.gov/2021/Graduation_Rate_2021_Dec062021.csv",
            "https://download.gosa.ga.gov/2022/Graduation_Rate_2022_Dec082022.csv"
        ].include? url
            s_id = item[4]
            d_id = item[2]
            if type == "District" 
                return { 
                    is_district: 1,
                    district_id: nil,
                    number: d_id.to_i,
                    name: item[3],
                    state:"GA",
                    data_source_url: url 
                }
            else
                return { 
                    is_district: 0,
                    district_id: d_id, # This will be replaced during insertion
                    number: s_id.to_i,
                    name: item[5],
                    state:"GA",
                    data_source_url: url 
                }
            end
        end
    end

    def get_general_info_from_graduation_5_year_cohort(url, type, item)        
        s_id = item[4]
        d_id = item[2]
        if type == "District" 
            return { 
                is_district: 1,
                district_id: nil,
                number: d_id.to_i,
                name: item[3],
                state:"GA",
                data_source_url: url 
            }
        else
            return { 
                is_district: 0,
                district_id: d_id, # This will be replaced during insertion
                number: s_id.to_i,
                name: item[5],
                state:"GA",
                data_source_url: url 
            }
        end
    end

    def get_general_info_from_graduation_hope(url, type, item)
        if [
            "https://download.gosa.ga.gov/2004/Exports/hope.csv",
            "https://download.gosa.ga.gov/2006/Exports/Hope.xls",
            "https://download.gosa.ga.gov/2007/Exports/Hope.xls",
            "https://download.gosa.ga.gov/2010/Exports/Hope.xls",
        ].include? url
            i1 = item[0].split(":")
            d_id = i1[0]
            s_id = i1[1]
            if type == "District"
                return { 
                    is_district: 1,
                    district_id: nil,
                    number: d_id.to_i,
                    name: item[1],
                    state:"GA",
                    data_source_url: url 
                }
            else
                return { 
                    is_district: 0,
                    district_id: d_id, # This will be replaced during insertion
                    number: s_id.to_i,
                    name: item[2],
                    state:"GA",
                    data_source_url: url 
                }
            end
        elsif url == "https://download.gosa.ga.gov/2008/Exports/HOPE_Eligibility_2008.xls"
            if item.length == 9
                return {
                    is_district: 1,
                    district_id: nil,
                    number: item[4].to_i,
                    name: item[5],
                    state:"GA",
                    data_source_url: url 
                }
            else
                if type == "District"
                    return {
                        is_district: 1,
                        district_id: nil,
                        number: item[4].to_i,
                        name: item[6],
                        state:"GA",
                        data_source_url: url 
                    }
                else
                    return {
                        is_district: 0,
                        district_id: item[4], # This will be replaced during insertion
                        number: item[5].to_i,
                        name: item[6],
                        state:"GA",
                        data_source_url: url 
                    }
                end
            end
        elsif [
            "https://download.gosa.ga.gov/2011/Graduation_Rate_2011_MAR_23_2020.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2012_4yr.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2013_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2014_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2015_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2016_DEC_1st_2016.csv",
            "https://gosa.georgia.gov/sites/gosa.georgia.gov/files/related_files/site_page/Graduation_Rate_2017_DEC_1st_2017.csv",
            "https://download.gosa.ga.gov/2018/Graduation_Rate_2018_JAN_24th_2019.csv",
            "https://download.gosa.ga.gov/2019/Graduation_Rate_2019_Dec2nd_2019.csv",
            "https://download.gosa.ga.gov/2020/Graduation_Rate_2020_Dec112020.csv",
            "https://download.gosa.ga.gov/2021/Graduation_Rate_2021_Dec062021.csv",
            "https://download.gosa.ga.gov/2022/Graduation_Rate_2022_Dec082022.csv"
        ].include? url
            s_id = item[1]
            d_id = item[2]
            if type == "District"
                return { 
                    is_district: 1,
                    district_id: nil,
                    number: d_id.to_i,
                    name: item[1],
                    state:"GA",
                    data_source_url: url 
                }
            else
                return { 
                    is_district: 0,
                    district_id: d_id, # This will be replaced during insertion
                    number: s_id.to_i,
                    name: item[2],
                    state:"GA",
                    data_source_url: url 
                }
            end
        end
    end    
### To gather general_info 

    def parse_item(section_name, item, general_id, url, headers)
        if section_name == "ga_enrollment_by_grade"
            return parse_ga_enrollment_by_grade(headers, item, general_id, url)
        elsif section_name == "ga_enrollment_by_subgroup"
            return parse_ga_enrollment_by_subgroup(headers, item, general_id, url)
        elsif section_name == "ga_assessment_eoc_by_grade"
            return parse_ga_assessment_eoc_by_grade(headers, item, general_id, url)
        elsif section_name == "ga_assessment_eoc_by_subgroup"
            return parse_ga_assessment_eoc_by_subgroup(headers, item, general_id, url)
        elsif section_name == "ga_assessment_eog_by_grade"
            return parse_ga_assessment_eog_by_grade(headers, item, general_id, url)
        elsif section_name == "ga_assessment_eog_by_subgroup"
            return parse_ga_assessment_eog_by_subgroup(headers, item, general_id, url)
        elsif section_name == "ga_graduation_4_year_cohort"
            return parse_ga_graduation_4_year_cohort(headers, item, general_id, url)
        elsif section_name == "ga_graduation_5_year_cohort"
            return parse_ga_graduation_5_year_cohort(headers, item, general_id, url)
        elsif section_name == "ga_salaries_benefits"
            return parse_ga_salaries_benefits(headers, item, general_id, url)
        elsif section_name == "ga_revenue_expenditure"
            return parse_ga_revenue_expenditure(headers, item, general_id, url)
        elsif section_name == "ga_graduation_hope"
            return parse_ga_graduation_hope(headers, item, general_id, url)
        else
            @logger.info "No Parser for Given Section".red
        end 
    end


    private

    def links_extractor(content, title)
        data = Nokogiri::HTML(content)
        sections = data.search('//tr').select{ |section| 
            section.text.include?(title)
        }
        cols = sections.first.search('td')
        col_rows = cols[1].search('p')  
        link_tags = col_rows[1].search('a')
        links = link_tags.map{ |link|
            link['href']
        }
        links
    end

    def fix_year_field(year_field)
        years = year_field.split("-")
        if years[1].length == 2
            years[1] = "20#{years[1]}"
        end
        years.join("-")
    end

end