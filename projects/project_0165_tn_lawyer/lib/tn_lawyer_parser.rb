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

  html_list_lawyers = doc.css('.table tbody').css('tr')
  html_list_lawyers.each do |tr|

    columns = tr.css('td')

    new_lawyer={
      bar_number:           columns[0].content,
      name:                 columns[1].content,
      law_firm_city:        columns[2].content,
      law_firm_county:      columns[3].content,
      registration_status:  columns[4].content,

                 }
    new_lawyer[:link] = "https://www.tbpr.org/attorneys/" + new_lawyer[:bar_number]

    if new_lawyer[:name].match(/\(\w*/)
      new_lawyer[:name] = new_lawyer[:name].match(/\(([\w\W]*)\)/)[0][1...-1]
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
    p new_lawyer
    lawyers.push(new_lawyer)
  end
  lawyers
end

def parse_list_lawyers_abc(html)
  doc = Nokogiri::HTML(html)
  lawyers = []

  html_list_lawyers = doc.css('div.content-primary ul').css('li')
  html_list_lawyers.each do |li|

    link = li.css('a')[0]
    new_lawyer={
      bar_number:           link['href'].split('/')[-1],
      name:                 link.content.split(',')[0..1].join(','),
      link:                 "https://www.tbpr.org" +link['href'],
      law_firm_city:        link.content.split(',')[-1]

    }


    new_lawyer.each_pair do |key, value|
      if value.instance_of? String
        if value.strip==''
          new_lawyer[key] = nil
        else
          new_lawyer[key] = value.strip
        end
      end
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

ADDITIONAL_LAWYER = { "Licensed in TN Since:"=> :date_admitted, "Address:"=> :law_firm_address,
                      "Law School:" => :law_school, "Office County:" => :law_firm_county
                      #"Status:\n    " => :registration_status
}

def parse_lawyer(html)
  doc = Nokogiri::HTML(html)


  lawyer = {:date_admitted=>nil, :law_firm_name=>nil, :law_firm_address=>nil,
            :law_firm_state=>nil, :law_firm_zip=>nil, :registration_status=>nil}
  body = doc.css('.content')[0]

  values = body.css('dd')


  body.css('dt').each_with_index do |label, i|
    label = label.content

    if label.include?('Status:')
      status = values[i+3].css('.js-btn')[0].content
      lawyer[:registration_status] = status.split(' (')[0].strip
      status_date = status.match(/\(([^)]+)\)/)
      lawyer[:registration_status_date] = status_date ? status_date[1] : nil
    end

    next if !label.in? ADDITIONAL_LAWYER.keys

    lawyer[ADDITIONAL_LAWYER[label]] = values[i+3].content

    if label == "Address:"
      address = ''
      values[i..i+3].each do |row|
        next if row.content.strip.in? ["", 'This attorney is deceased.']
        address+= row.content.strip + "\n"
      end
      next if address.strip == ''
      lawyer[ADDITIONAL_LAWYER[label]] = address
      divided_address = address.strip.split("\n")

      if divided_address[-1].match(/\d+/)
        lawyer[:law_firm_zip] = divided_address[-1]
      else
        divided_address.push(nil)
      end

      lawyer[:law_firm_state] = divided_address[-2].split(',')[-1].strip if divided_address.length>1
      # if divided_address.length>3
      #   lawyer[:law_firm_name] = divided_address[0]
      # end

    end
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

  used_names = []
  doc.css('.content').each do |cont|
    if !cont.css('h3')[0].nil? && cont.css('h3')[0].content == 'Names Used:'
      cont.css('tbody').css('td').each do |name|
        used_names.push(name.content.strip)
      end
    end
  end

  lawyer[:used_names] =
    if !used_names.empty?
      used_names.join('; ')
    else
      nil
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


  p lawyer

  unless lawyer[:date_admitted].nil?
    lawyer[:date_admitted] = Date.new(lawyer[:date_admitted].to_i, 1,1)
  end

  lawyer
end