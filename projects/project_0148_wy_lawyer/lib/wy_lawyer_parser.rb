# frozen_string_literal: true

def parse_list_lawyers(html)
  doc = Nokogiri::HTML(html)
  lawyers = []
  #date_news = Date.new()
  html_list_lawyers = doc.css('.searchResults').css('.searchResultRow')
  html_list_lawyers.each do |lawyer|
    lawyer
    lawyers.push({})

    link = lawyer.css('td a')[0]

    lawyers[-1][:link] = link['href']
    lawyers[-1][:name] = link.content.encode('UTF-8', :invalid => :replace)

    lawyers[-1][:bar_number] = link['href'].split('?id=')[-1]

    city_zip = lawyer.content.split(link.content)[-1].split(',')

    lawyers[-1][:law_firm_city] = city_zip[0].strip
    lawyers[-1][:law_firm_state] = city_zip[1].strip

  end
  lawyers
end


def parse_lawyer(html)
  doc = Nokogiri::HTML(html)

  hash_name = { "County:"=> :law_firm_county, "Admission Date:"=> :date_admitted, #"Mailing Address"=> :law_firm_address,
                "Status:"=> :registration_status, "Firm:"=> :law_firm_name, "Phone:" => :phone, "Email:" => :email,
                "Fax:" => :fax_number, "Website:" => :law_firm_website,
                "Other Jurisdictions:" => :other_jurisdictions, "Judicial District:" => :judicial_district,
                "Public Discipline:" => :public_discipline,
  }

  lawyer = {:law_firm_county=>nil, :date_admitted=>nil, :law_firm_address=>nil, :law_firm_name=>nil,
            :phone=>nil, :email=>nil, :law_firm_zip=>nil, :registration_status=>nil,
            :fax_number=>nil, :law_firm_website=>nil, :other_jurisdictions=>nil,
            :judicial_district=>nil, :public_discipline=>nil,}
  body = doc.css('.entry-content')[0]

  body.css('p').each do |row|
    row_name = row.css('strong')[0]
    next if row_name.nil?
    row_name = row_name.content
    if row_name.in?(hash_name.keys)
      lawyer[hash_name[row_name]] = row.content.split(row_name)[-1].strip
    # elsif row_name=="Mailing Address"
    #   row.css('div')[1].css('br').each { |br| br.replace("\n") }
    #   law_firm_addresses = row.css('div')[1].content.strip
    #   lawyer[:law_firm_address], phone = law_firm_addresses.split('Office: ')
    #   lawyer[:law_firm_address] = lawyer[:law_firm_address].strip
    #   lawyer[:phone] = phone.split("\n")[0] unless phone.nil?
    #   state_zip = lawyer[:law_firm_address].scan(/ [A-Z]{2} \d{4,5}\-?\d+/)[0]
    #   if !state_zip.nil?
    #     lawyer[:state], lawyer[:law_firm_zip] = state_zip.strip.split(' ')
    #   end
    end
  end

  law_firm_addresses = ''
  nokogiri_address = body.css('.address')[0]
  if !nokogiri_address.nil?
    law_firm_addresses = ''
    nokogiri_address.css('p').each do |p|
      next if ["Mailing Address", "Physical Address"].include?(p.content)
      law_firm_addresses += p.content + "\n"
    end
    lawyer[:law_firm_address] = law_firm_addresses.strip
    divided_address = law_firm_addresses.strip.split("\n")
    lawyer[:law_firm_name] = divided_address[0] if divided_address.length>2

    state_zip = divided_address[-1].scan(/ [A-Z]{2} \d{4,5}\-?\d+/)[0]
    lawyer[:law_firm_zip] = state_zip.strip.split(' ')[-1] unless state_zip.nil?
  end



  lawyer[:law_firm_county] = nil if lawyer[:law_firm_county]=="N/A"

  unless lawyer[:date_admitted].nil?
    lawyer[:date_admitted] = Date.strptime(lawyer[:date_admitted], '%m/%d/%Y')
  end



  lawyer
end