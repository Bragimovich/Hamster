module ParserHelper

  def get_dynamic_index(data)
    data.map.with_index {|val, index| [val, index] }.to_h
  end

  def get_sub_group_data
    [["Total", ["Total Enrollment"]], ["Ethnicity", ["American Indian/Alaskan Native", "Asian", "Hispanic", "Black", "White", "Pacific Islander", "Two or More Races"]], ["Gender", ["Male", "Female"]], ["Special Populations", ["IEP", "EL (English Learners)", "English Learners Continuously Enrolled", "English Learners Proficient", "FRL Eligible", "FRL Receiver", "FRB Eligible", "FRB Receiver", "Migrant"]], ["Grade", ["Grade PK", "Grade KK", "Grade 01", "Grade 02", "Grade 03", "Grade 04", "Grade 05", "Grade 06", "Grade 07", "Grade 08", "Grade 09", "Grade 10", "Grade 11", "Grade 12", "Grade 13"]]].to_h
  end

  def get_financial_data_hash
    [["Fund", ["Federal", "State/Local", "Total"]], ["Type", ["Personnel", "Non-Personnel"]], ["Spending Name", ["Instruction", "Instruction Support", "Operations", "Leadership"]]].to_h
  end

  def get_incidents_hash_data
    {"Incidents"=> ["Including Weapons", "Including Violence", "Including Use of Alcoholic Beverages", "Including Posession of Alcoholic Beverages", "Including Use of Cont Subs", "Including Poss of Cont Subs"]}
  end

  def get_grade_hash_data
    {"Grade"=> ["Total", "Grade 6", "Grade 7", "Grade 8", "Grade 9", "Grade 10", "Grade 11", "Grade 12", "Grades 9-12"]}
  end

  def read_csv(file_path)
    CSV.read(file_path)
  end

  def get_general_info_id(general_id_info, organization_code)
    if general_id_info.select{ |a| a[0] == organization_code}.empty?
      id = general_id_info.select{ |a| a[0] == nil}[0].last
    else
      id = general_id_info.select{ |a| a[0] == organization_code}[0].last
    end
    id
  end
end
