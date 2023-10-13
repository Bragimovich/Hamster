# frozen_string_literal: true
require 'roo'

class Parser < Hamster::Parser
    def get_links(file_content)
        parsed_content =  Nokogiri::HTML(file_content)
        target_area = parsed_content.at_css("div.callout-two_columns-sidebar") 
        headings = target_area.search('h3')

        salaries_link =  headings[0].next_element.search('a')[0]["href"]
        earnings_link =  headings[1].next_element.search('a')[0]["href"]

        {
            "salaries_link": salaries_link,
            "earnings_link": earnings_link
        }
    end


    def salaries_file_parser(file_path)
        records = []
        xlsx = Roo::Excelx.new(file_path)
        arr = xlsx.as_json
        arr[1..].each{ |item|
            records << {        
                as_of_date: item[0],
                preferred_last_name: item[1],
                preferred_first_name: item[2],
                cost_center_hierarchy_cch6: item[3],
                cost_center: item[4],
                job_profile: item[5],
                fte: item[6],
                pay_rate_type: item[7],
                base_pay_psn: item[8],
                position_group: item[9],
                identifier: item[10],
            }
        }
        records
    end

    
    def earnings_file_parser(file_path)
        records = []
        xlsx = Roo::Excelx.new(file_path)
        arr = xlsx.as_json
        arr[1..].each{ |item|
            records << {        
                last_legal_name: item[0],
                first_name_preferred: item[1],
                job_profile_name: item[2],
                cost_center: item[3],
                cost_center_hierarchy_cch6: item[4],
                position_group: item[5],
                regular_pay: item[6],
                bonus: item[7],
                overtime: item[8],
                other: item[9],
                gross_pay: item[10],
            }
        }
        records
    end

end
  