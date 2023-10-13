# frozen_string_literal: true


HASH_ADDRESS = {
  "streetAddress"=> :law_firm_address,
  "addressLocality" => :law_firm_city, "addressRegion" =>:law_firm_state , "postalCode" =>:law_firm_zip,
}

HASH_CONTACTS = {
  'Phone: ' => :phone, 'Areas of Practice: ' => :sections,
}

def parse_list_lawyers(html)
  doc = Nokogiri::HTML(html)
  lawyers = []

  html_list_lawyers = doc.css('.container-fluid').css('.row-fluid')
  html_list_lawyers[3..].each do |lawyer_on_page|


    #lawyers[-1][:link] = link['href']
    new_lawyer={
          name: nil,
          law_firm_name:        nil,
          law_firm_city:        nil,
          law_firm_address:     nil,
          law_firm_state:     nil,
          law_firm_zip:     nil,
          phone:                nil,
          sections:                nil,

                 }

    new_lawyer[:name] = lawyer_on_page.css('.MCDirectoryName')[0].content.gsub(/,\s*/, ' ').gsub("\n", ' ')
    new_lawyer[:law_firm_name] = lawyer_on_page.css('.MCDirectoryCompany')[0].content
    lawyer_on_page.css('div').each do |div|
      if div['itemprop'] == 'address'
        div.css('span').each do |span|
          label_address = span['itemprop']
          new_lawyer[HASH_ADDRESS[label_address]] = span.content
        end
      end
    end

    lawyer_on_page.css('.MCDirectoryField').each do |field|
      label = field.css('.MCDirectoryFieldLabel')[0].content
      next unless label.in?(HASH_CONTACTS.keys)
      value = field.css('.MCDirectoryFieldValue')[0].content

      new_lawyer[HASH_CONTACTS[label]] = value
    end


    new_lawyer.each_pair do |key, value|
      if value.instance_of? String
        if value.strip==''
          new_lawyer[key] = nil
        else
          new_lawyer[key] = value.strip
        end
      end
    end

    new_lawyer[:link] = 'https://www.memphisbar.org' +
      lawyer_on_page.css('button')[0]['onclick'].split("'")[1]
    new_lawyer[:bar_number] = new_lawyer[:link].split('&dirMemberid=')[-1].to_i
    lawyers.push(new_lawyer)
  end
  lawyers
end

def parse_count(html)
  doc = Nokogiri::HTML(html)
  counts = doc.css('.results-count')[0].content.split(' ')[0].to_i
  counts
end

def parse_lawyer(html)
  doc = Nokogiri::HTML(html)
  hash_name = { "License Type:"=> :type, "WSBA Admit Date:"=> :date_admitted, #"Public/Mailing Address:"=> :law_firm_address,
                "Practice Areas:"=> :sections, "Email:" => :email, "Firm or Employer:" => :law_firm_name,
                #"Phone:" => :phone, "License Status:"=> :registration_status, "License Number:" => :bar_number,
  }

  lawyer = {:type=>nil, :date_admitted=>nil, :law_firm_name=>nil, :law_firm_address=>nil,
            :law_firm_state=>nil, :law_firm_zip=>nil, :email=>nil,  :sections=>nil,}
  body = doc.css('.LegalProfileControl_PersonifyDefault')[0]

  lawyer[:name] = body.css('#dnn_ctr2977_DNNWebControlContainer_ctl00_lblMemberName')[0].content


  body.css('tr').each do |row|
    row_name = row.css('td strong')[0]
    next if row_name.nil?
    row_name = row_name.content
    if row_name.in?(hash_name.keys)
      lawyer[hash_name[row_name]] = row.css('td')[1].content
      # elsif row_name=="Public/Mailing Address:"
      #   row.css('td')[1].css('br').each { |br| br.replace("\n") }
      #   lawyer[:law_firm_address] = row.css('td')[1].content.strip.split("\n")[0...-1].join("\n").strip
      #
      #
      #   state_zip = lawyer[:law_firm_address].scan(/ [A-Z]{2} \d{4,5}\-?\d+/)[0]
      #   if !state_zip.nil?
      #     lawyer[:state], lawyer[:law_firm_zip] = state_zip.strip.split(' ')
      #   end
    end
  end

  law_firm_address = body.css('#dnn_ctr2977_DNNWebControlContainer_ctl00_lblAddress')[0]
  unless law_firm_address.nil?
    law_firm_address.css('br').each { |br| br.replace("\n") }
    lawyer[:law_firm_address] = law_firm_address.content.strip.split("\n")[0...-1].join("\n").strip
    state_zip = lawyer[:law_firm_address].scan(/ [A-Z]{2} \d{4,5}\-?\d+/)[0]
    lawyer[:law_firm_state], lawyer[:law_firm_zip] = state_zip.strip.split(' ') if !state_zip.nil?
  end

  lawyer.each_pair do |key, value|
    lawyer[key] = nil if value=='' or value == "None Specified"
  end


  unless lawyer[:date_admitted].nil?
    lawyer[:date_admitted] = Date.strptime(lawyer[:date_admitted], '%m/%d/%Y')
  end

  lawyer
end