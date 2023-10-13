class Parser < Hamster::Parser

  def main_page(response)
    document = Nokogiri::HTML(response.force_encoding('utf-8'))
    link = document.css("span.l-display-ib a")[0]['href']
    source_updated_at = document.css("span.l-display-ib")[0].text.split(":")[1].strip
    source_updated_at = Date.parse(source_updated_at ) rescue nil
    [link, source_updated_at]
  end

  def csv_file_reading(file, link, run_id, source_updated_at)
    csv_data_array = []
    doc = File.read(file[0])
    all_data = CSV.parse(doc, :headers => true)
    all_data.each do |data|
        final_data = {}
        employ_date = DateTime.strptime(data["HIREDT"], "%m/%d/%Y").to_date
        final_data[:state_number] = data["STATENUM"]
        final_data[:run_id] = run_id
        final_data[:agency]=data["AGY"]
        final_data[:agency_name]=remove_spaces(data["NAME"])
        final_data[:last_name]=remove_spaces(data["LASTNAME"])
        final_data[:first_name]=remove_spaces(data["FIRSTNAME"])
        final_data[:middle_name]=data["MI"]
        final_data[:class_code] = remove_spaces(data["JOBCLASS"])
        final_data[:class_title] = remove_spaces(data["JC TITLE"])
        final_data[:ethnicity] = remove_spaces(data["RACE"])
        final_data[:gender] =remove_spaces(data["SEX"])
        final_data[:status] = remove_spaces(data["EMPTYPE"])
        final_data[:employ_date] = employ_date
        final_data[:hrly_rate] = data["RATE"]
        final_data[:hrs_per_wk] = data["HRSWKD"]
        final_data[:monthly] =data["MONTHLY"]
        final_data[:annual] = data["ANNUAL"]
        final_data[:duplicated] = data["duplicated"]
        final_data[:multiple_full_time_jobs] = data["multiple_full_time_jobs"]
        final_data[:combined_multiple_jobs] = data["combined_multiple_jobs"]
        final_data[:hide_from_search] = data["hide_from_search"]
        final_data[:summed_annual_salary] = data["summed_annual_salary"]
        final_data[:source_updated_at] = source_updated_at
        csv_data_array << final_data
    end
    csv_data_array
  end

  private

  def remove_spaces(data)
    data.strip
  end

end
