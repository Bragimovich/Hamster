# frozen_string_literal: true


HASH_LAWYER = {
  "FullName"=> :name, "SupremeCourtNumber" => :bar_number,
  "FirstName" => :first_name, "LastName" => :last_name, "MiddleName" => :middle_name,

  "LawFirm" => :law_firm_name,
  "CompanyAddressLine1"=> :law_firm_address, "CompanyAddressLine2" => :law_firm_address2,
  "City" => :law_firm_city, "State" =>:law_firm_state , "Zipcode" =>:law_firm_zip,

  "Url" => :link, "OfficePhone" => :phone, "WorkEmail" => :email
}

def parse_list_lawyers(html)
  lawyers = []
  not_parsed_list_lawyers = JSON.parse(html)

  not_parsed_list_lawyers['results']['Lawyers'].each do |not_parsed_lawyer|

    if not_parsed_lawyer['IsMember']==true
      status = 'Active'
    else
      status = nil
    end

    parsed_lawyer = {
      sections: nil, registration_status: status, json_text: not_parsed_lawyer.to_s,
    }

    not_parsed_lawyer.each_pair do |key, value|
      parsed_lawyer[HASH_LAWYER[key]] = value
    end

    parsed_lawyer[:link] = "https://www.ohiobar.org" + parsed_lawyer[:link]

    not_parsed_lawyer["PracticeAreas"].each do |area|
      area = area["Name"].gsub(' ',' ')
      if parsed_lawyer[:sections]
        parsed_lawyer[:sections] += ", #{area}"
      else
        parsed_lawyer[:sections] = area
      end
    end

    if parsed_lawyer[:law_firm_address2]
      parsed_lawyer[:law_firm_address] += ', ' + parsed_lawyer[:law_firm_address2] if parsed_lawyer[:law_firm_address2].strip!=''
    end

    parsed_lawyer.delete(:law_firm_address2)
    parsed_lawyer.delete(nil)

    if !not_parsed_lawyer["Overview"]["Admissions"].empty?
      date_admitted = not_parsed_lawyer["Overview"]["Admissions"][0]["DateOfAdmission"]
      parsed_lawyer[:date_admitted] = Date.strptime(date_admitted, '%m/%d/%Y')
    else
      parsed_lawyer[:date_admitted] = nil
    end

    parsed_lawyer.each_pair do |key, value|
      if value.instance_of? String
        if value.strip==''
          parsed_lawyer[key] = nil
        else
          parsed_lawyer[key] = value.strip
        end

      end
    end

    lawyers.push(parsed_lawyer)

  end
  lawyers
end





