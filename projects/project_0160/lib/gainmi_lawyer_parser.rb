# frozen_string_literal: true

GENERAL_LAWYER = {
  "displayName"=> :name,
  "firstName" => :first_name, "lastName" => :last_name, "middleName" => :middle_name,
  "id" => :bar_number,
  "memberType"=> :registration_status,
  "firmName" => :law_firm_name,
  "vanityURLFull" => :link,
  "email" => :email,

}

ADDRESS_LAWYER = {
  "street"=> :law_firm_address,
  "city"=> :law_firm_city,
  "suite"=> :law_firm_address_additional,
  "region"=> :law_firm_state,
  "postalCode"=>:law_firm_zip,
  "phone"=>:phone,
  "county"=>:law_firm_county,
}

def parse_list_lawyers(html, state)
  lawyers = []
  not_parsed_list_lawyers = JSON.parse(html)
  not_parsed_list_lawyers.each do |not_parsed_lawyer|
    parsed_lawyer = {}
    not_parsed_lawyer.each_pair do |key, value|
      parsed_lawyer[GENERAL_LAWYER[key]] = value
    end

    not_parsed_lawyer["primaryLocation"].each_pair do |key, value|
      parsed_lawyer[ADDRESS_LAWYER[key]] = value
    end

    if parsed_lawyer[:law_firm_address_additional]
      parsed_lawyer[:law_firm_address] += ', ' + parsed_lawyer[:law_firm_address_additional] if parsed_lawyer[:law_firm_address_additional].strip!=''
    end

    parsed_lawyer.delete(:law_firm_address_additional)
    parsed_lawyer.delete(nil)

    if !not_parsed_lawyer["licenses"].empty?
      parsed_lawyer[:date_admitted] = not_parsed_lawyer["licenses"][0]["yearAdmission"]
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

    unless parsed_lawyer[:date_admitted].nil?
      parsed_lawyer[:date_admitted] =
        case state
        when :georgia
          Date.strptime(parsed_lawyer[:date_admitted], '%m/%d/%Y')
        when :michigan
          begin
            Date.strptime(parsed_lawyer[:date_admitted], '%m/%d/%Y')
          rescue
            Date.new(parsed_lawyer[:date_admitted].to_i, 1,1) if parsed_lawyer[:date_admitted].match(/^\d{4}$/)
          end
        when :indiana
          Date.strptime(parsed_lawyer[:date_admitted], '%Y-%m-%d')
        end

    end

    lawyers.push(parsed_lawyer)

  end
  lawyers
end






