require 'json'

class Parser < Hamster::Parser
  def initialize
    super
  end

  def get_links_from_landing_page(html)
    target_report_names = ["Employee Pay Rates", "Employment History", "Agency Heads"]
    ids = []
    document = Nokogiri::HTML(html)
    script_tag = document.at_css('script')
    if script_tag
      content = script_tag.content.strip
      json_str = content.gsub(/var gon = /, '')
      json_obj = JSON.parse(json_str.match(/{.*}/)[0])
      reports = json_obj['reports']
      reports.map do  |report|
        if target_report_names.include?(report["name"])
          ids << report["id"]
        end
      end
    else
      Hamster.report(to: 'Farzpal Singh', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nNo JSON object found", use: :slack)
    end
    ids
  end

  def get_hashes(csv_file_path, query)
    hashes = csv_to_hashes(csv_file_path)
    csv_data = get_data_from_csv(hashes, query)
  end

  def csv_to_hashes(file_path)
    lines = CSV.read(file_path, headers: true, header_converters: :symbol)
    hashes = lines.map(&:to_h)
    hashes
  end

  def get_data_from_csv(hashes, id)
    csv_info = []

    hashes.map do |hash|
      info_hash = {}
      if id ==  29262
        info_hash['employee_name'] =  hash[:employee_name]
        info_hash['job_title'] =  hash[:job_title]
        info_hash['agency_name'] =  hash[:agency_name]
        info_hash['pay_rate'] =  hash[:pay_rate]
        info_hash['pay_basis'] =  hash[:pay_basis]
        info_hash['full_or_part_status'] =  hash[:fulltimeparttime]
        info_hash['agency_code'] =  hash[:agency_code ]
        info_hash['annual_salary'] =  hash[:annual_salary]
        info_hash['class_code'] =  hash[:class_code]
        info_hash['appointment_type'] =  hash[:appointment_type]
        info_hash['date_of_load'] =  hash[:date_of_load]
        info_hash['employee_count'] =  hash[:employee_count]
        info_hash['work_county'] =  hash[:work_county]

        csv_info << info_hash
      elsif id == 35465
        info_hash['employee_name'] =  hash[:employee_name]
        info_hash['job_title'] =  hash[:job_title]
        info_hash['agency_name'] =  hash[:agency_name]
        info_hash['pay_rate'] =  hash[:pay_rate]
        info_hash['pay_basis'] =  hash[:pay_basis]
        info_hash['full_or_part_status'] =  hash[:fulltimeparttime]
        info_hash['hire_date'] =  hash[:hire_date ]
        info_hash['seperation_date'] =  hash[:separation_date]
        info_hash['months_at_agency'] =  hash[:months_at_agency]
        info_hash['appointment_type'] =  hash[:appointment_type]
        info_hash['prior_record'] =  hash[:prior_record_ind]
        info_hash['status'] =  hash[:status]
        csv_info << info_hash
      else
        info_hash['employee_name'] =  hash[:name]
        info_hash['job_title'] =  hash[:job_title]
        info_hash['agency_name'] =  hash[:agency_name]
        info_hash['agency_code'] =  hash[:agency_code ]
        info_hash['annual_salary'] =  hash[:annual_salary]
        info_hash['date_of_load'] =  hash[:date_of_load]

        csv_info << info_hash
      end
    end
    return csv_info
  end
end
