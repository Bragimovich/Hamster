# frozen_string_literal: true



def parse_list_lawyers(html)
  doc = Nokogiri::HTML(html)
  lawyers = []

  html_list_lawyers = doc.css('#myTable_off').css('tr')
  html_list_lawyers[1..].each do |tr|

    columns = tr.css('td')

    new_lawyer={
      bar_number:           columns[0].content,
      name:                 columns[1].content,
      law_firm_name:        columns[2].content,
      type:                 columns[3].content,
      registration_status:  columns[4].content,
      date_admitted:        columns[6].content,
                 }


    new_lawyer[:link] = "https://member.alaskabar.org/cvweb/cgi-bin" + columns[1].css('a')[0]['href'][2..]


    new_lawyer.each_pair do |key, value|
      if value.instance_of? String
        if value.strip==''
          new_lawyer[key] = nil
        else
          new_lawyer[key] = value.strip
        end
      end
    end

    unless new_lawyer[:date_admitted].nil?
      new_lawyer[:date_admitted] = Date.strptime(new_lawyer[:date_admitted], '%m/%d/%Y')
    end

    lawyers.push(new_lawyer)
  end
  lawyers
end


def parse_count(html)
  doc = Nokogiri::HTML(html)
  counts = doc.css('.results-count')[0].content.split(' ')[0].to_i
  counts
end

ADDITIONAL_LAWYER = { "Prefix"=> :name_prefix, "First Name"=> :first_name, "Last Name" => :last_name, "Middle Name" => :middle_name,
                      "Law School" => :law_school,
}


def parse_lawyer(html)
  doc = Nokogiri::HTML(html)


  lawyer = {:name_prefix=>nil, :first_name=>nil, :last_name=>nil,
            :middle_name=>nil, :law_school=>nil}


  values = doc.css('dd')


  doc.css('dt').each_with_index do |label, i|
    label = label.content
    next if !label.in? ADDITIONAL_LAWYER.keys

    lawyer[ADDITIONAL_LAWYER[label]] = values[i].content

  end

  # law_firm_address = body.css('#dnn_ctr2977_DNNWebControlContainer_ctl00_lblAddress')[0]
  # unless law_firm_address.nil?
  #   law_firm_address.css('br').each { |br| br.replace("\n") }
  #   lawyer[:law_firm_address] = law_firm_address.content.strip.split("\n")[0...-1].join("\n").strip
  #   state_zip = lawyer[:law_firm_address].scan(/ [A-Z]{2} \d{4,5}\-?\d+/)[0]
  #   lawyer[:law_firm_state], lawyer[:law_firm_zip] = state_zip.strip.split(' ') if !state_zip.nil?
  # end

  lawyer.each_pair do |key, value|
    if value.instance_of? String
      if value.strip==''
        lawyer[key] = nil
      else
        lawyer[key] = value.strip
      end
    end
  end

  lawyer
end


HASH_ADDRESS = {
  "Mailing Address "=> :law_firm_address,
  "City" => :law_firm_city, "State/Province" =>:law_firm_state , "Zip/Postal Code" =>:law_firm_zip,
  "Email Address" => :email, "Work Phone" => :phone
}

def parse_address_lawyer(html)
  doc = Nokogiri::HTML(html)


  address_lawyer = {:law_firm_city=>nil, :email=>nil, :law_firm_address=>nil,
            :law_firm_state=>nil, :law_firm_zip=>nil, :phone=>nil}

  dt = doc.css('dt')
  dd = doc.css('dd')

  dt.each_with_index do |row_name, i|
    row_name = row_name.content
    address_lawyer[HASH_ADDRESS[row_name]] = dd[i].content
  end

  address_lawyer.each_pair do |key, value|
    if value.instance_of? String
      if value.strip==''
        address_lawyer[key] = nil
      else
        address_lawyer[key] = value.strip
      end
    end
  end

  address_lawyer.delete(nil)
  address_lawyer

end