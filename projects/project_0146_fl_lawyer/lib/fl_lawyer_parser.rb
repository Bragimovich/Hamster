# frozen_string_literal: true

def parse_list_lawyers(html)
  doc = Nokogiri::HTML(html)
  lawyers = []
  #date_news = Date.new()
  html_list_lawyers = doc.css('.section-body').css('li').css('.profile-compact')
  html_list_lawyers.each do |lawyer|
    lawyer
    lawyers.push({})

    lawyers[-1][:bar_number]   = lawyer.css('.profile-bar-number span')[0].content.strip[1..].to_i
    link = lawyer.css('.profile-name a')[0]
    lawyers[-1][:link]   = 'https://www.floridabar.org/mybarprofile/' + lawyers[-1][:bar_number].to_s
    lawyers[-1][:name]  = link.content.encode('UTF-8', :invalid => :replace)
    #lawyers[-1][:contact_info] = lawyer.css('.profile-contact')[0].to_s.strip

  end
  lawyers
end


def parse_lawyer(html)
  doc = Nokogiri::HTML(html)

  hash_name = { "County:"=> :law_firm_county, "Admitted:"=> :date_admitted, #"Mail Address:"=> :law_firm_address,
                "Sections:"=> :sections, "Firm:"=> :law_firm_name, "Law School:"=> :law_school,
                "Firm Website:" => :law_firm_website,
                "Circuit:" => :judicial_district,  "Federal Courts:" => :courts_of_admittance,
                "Practice Areas:" => :professional_affiliation, "Firm Position:"=>:law_firm_position,
                "Bar Number:"=>:bar_number, "Personal Bar URL:" => :link
  }

  lawyer = {:law_firm_county=>nil, :date_admitted=>nil, :law_firm_address=>nil, :sections=>nil, :law_firm_name=>nil,
            :phone=>nil, :law_firm_state=>nil, :law_firm_zip=>nil, :registration_status=>nil,
            :eligibility=>nil, :email=>nil, :law_school=>nil, :law_firm_city=>nil,
            :law_firm_website=>nil, :judicial_district=>nil, :courts_of_admittance=>nil,
            :professional_affiliation=>nil, :fax => nil, :law_firm_position=>nil,
            :bar_number=>nil,}
  body = doc.css('.container-fluid')[0]
  regex = /[\u{1f600}-\u{1f64f}]/
  body.css('.row').each do |row|
    next if row.css('div label')[0].nil?
    row_name = row.css('div label')[0].content
    if row_name.in?(hash_name.keys)
      lawyer[hash_name[row_name]] = row.css('div')[1].content.strip
    elsif row_name=="Mail Address:"
      row.css('div')[1].css('br').each { |br| br.replace("\n") }
      law_firm_addresses = row.css('div')[1].content.strip.encode('UTF-8', :invalid => :replace).gsub(regex, "")
      lawyer[:law_firm_address], phone = law_firm_addresses.split('Office: ')
      lawyer[:law_firm_address] = lawyer[:law_firm_address].strip
      unless phone.nil?
        lawyer[:phone] = phone.split("\n")[0]
        fax = phone.split('Fax: ')
        lawyer[:fax] = fax[0].split("\n")[0] unless fax.nil?
      end
      lawyer[:law_firm_city] = lawyer[:law_firm_address].split("\n")[-1].split(',')[0]
      state_zip = lawyer[:law_firm_address].scan(/ [A-Z]{2} \d{4,5}\-?\d+/)[0]
      if !state_zip.nil?
        lawyer[:law_firm_state], lawyer[:law_firm_zip] = state_zip.strip.split(' ')
      end
    end

    if !lawyer[:professional_affiliation].nil?
      lawyer[:professional_affiliation] = lawyer[:professional_affiliation].split("\n").map { |r| r.strip }.join('; ')
    end
    if !lawyer[:courts_of_admittance].nil?
      lawyer[:courts_of_admittance] = lawyer[:courts_of_admittance].split("\n").map { |r| r.strip }.join('; ')
    end

  end

  lawyer[:name] = doc.css('h1.full')[0].content.strip

  lawyer[:law_firm_county] = nil if lawyer[:law_firm_county]=="Non-Florida"

  unless lawyer[:date_admitted].nil?
    lawyer[:date_admitted] = Date.strptime(lawyer[:date_admitted], '%m/%d/%Y')
  end

  lawyer[:registration_status] = body.css('.member-status')[0].content.strip unless body.css('.member-status')[0].nil?
  lawyer[:eligibility] =  body.css('.eligibility')[0].content.strip unless body.css('.eligibility')[0].nil?

  unless lawyer[:sections].nil?
    lawyer[:sections] = lawyer[:sections].split(/\n\s*/).join("; ")
  end

  lawyer
end



def parse_law_schools(html) #html = searchpage
  doc = Nokogiri::HTML(html)
  ls = []
  doc.css('#law-school-selector')[0].css('option').each do |opt|
    #p opt.content
    opt.each do |q|
      ls.push(q[1]) if q[0]=='value'
    end
  end
  ls
end