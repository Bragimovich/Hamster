# frozen_string_literal: true

HASH_LAWYER = { "nickname"=> :name, "first_name" => :first_name, "last_name" => :last_name, "attorney_middle" => :middle_name,
                "attorney_barnumber" => :bar_number, "attorney_admissiondate"=> :date_admitted,

                "attorney_address1"=> :law_firm_address, "attorney_address2" => :law_firm_address2, "attorney_firmname"=> :law_firm_name,
                "attorney_city" => :law_firm_city, "attorney_state" =>:law_firm_state , "attorney_zipcode" =>:law_firm_zip,

                "attorney_membertype"=> :registration_status, "attorney_specialization" => :sections,
                "attorney_phone" => :phone, "attorney_cemail" => :email
}

def parse_list_lawyers(html)
  doc = Nokogiri::HTML(html)
  lawyers = []
  #date_news = Date.new()
  html_list_lawyers = doc.css('.usersearch').css('.user_chunk')
  html_list_lawyers.each do |lawyer|
    lawyer_info_not_parsed = lawyer.css('pre')[0].content
    parsed_lawyer = parse_one_lawyer(lawyer_info_not_parsed)

    lawyers.push(parsed_lawyer)

  end
  lawyers
end


def parse_one_lawyer(array)
  lawyer = {}
  array.split("\n").each do |key|
    matched_row = /\s*\[([^)]*?.)\] => ([\w\W]*)/.match(key)
    if !matched_row.nil?
      if matched_row.length==3
        lawyer[HASH_LAWYER[matched_row[1]]]=matched_row[2]
      end
    end
  end

  lawyer[:law_firm_address] += ', ' + lawyer[:law_firm_address2] if lawyer[:law_firm_address2].strip!=''
  lawyer.delete(:law_firm_address2)
  lawyer.delete(nil)

  lawyer.each_pair do |key, value|
    lawyer[key] = nil if value.strip==''
  end

  unless lawyer[:date_admitted].nil?
    lawyer[:date_admitted] = Date.strptime(lawyer[:date_admitted], '%m/%d/%Y')
  end

  type_status = /([A-Z]*) ([\w\W]*)|([\w\W]*)/.match lawyer[:registration_status]
  if !type_status[1].nil?
    lawyer[:type] = type_status[1]
    lawyer[:registration_status] = type_status[2]
  else
    lawyer[:type] = nil
  end

  lawyer
end



