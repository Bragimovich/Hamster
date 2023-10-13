require_relative '../lib/message_send'

class Parser < Hamster::Parser

  def items_parse(hamster)
    body = Nokogiri::HTML.parse(hamster.body)
    results_count = body.css('.attSearchRes').text.gsub(/\D+/, '').strip.to_i
    results = []
    items = body.css('#tblAttorney > tbody > tr')
    items.each do |item|
      link = "https://apps.calbar.ca.gov#{item.css('td')[0].css('a')[0][:href]}"
      name = item.css('td')[0].css('a').text.squeeze(' ').strip
      status = item.css('td')[1].text.strip
      number = item.css('td')[2].text.strip
      city = item.css('td')[3].text.strip
      admission_date = item.css('td')[4].text.strip
      results << {link: link, name: name, status: status, number: number, city: city, admission_date: admission_date}
    end
    [results, results_count]
  end

  def info_parse(page)
    body = Nokogiri::HTML.parse(page)
    data_source_url = body.css('.original_link').text.strip
    name = body.css('.original_name').text.strip.gsub(' ,',',')
    registration_status = body.css('.original_status').text.strip
    bar_number = body.css('.original_number').text.strip
    details = body.css('#content-main #moduleMemberDetail')
    first_name, middle_name, last_name = name_split(name)
    if details.css('div > h3').blank?
      date_admitted = nil
      address_original = nil
      law_firm_name = nil
      law_firm_address = nil
      law_firm_city = nil
      law_firm_state = nil
      law_firm_zip = nil
      phone = nil
      fax = nil
      email = nil
      website = nil
      law_school = nil
    else
      if details.css('div > h3')[1].text.include?('State Bar number')
        date_admitted = body.css('.original_admission_date').text.strip
        date_admitted = date_admitted.blank? ? nil : Date.strptime(date_admitted, '%B %Y')
        address_original = nil
        law_firm_name = nil
        law_firm_address = nil
        law_firm_city = body.css('.original_city').text.strip
        law_firm_city = nil if law_firm_city.blank?
        law_firm_state = nil
        law_firm_zip = nil
        phone = nil
        fax = nil
        email = nil
        website = nil
        law_school = nil
      else
        date_admitted = details.css('.margin-bottom table tbody tr')[-1].css('td')[0].text
        date_admitted = Date.strptime(date_admitted, '%m/%d/%Y')
        address_original, phone, fax, website, email = items_info(details)
        email = email_find(email, name)
        law_firm_name, law_firm_address, law_firm_city, law_firm_state, law_firm_zip = law_firm(address_original)
        law_school = law_school(details)
      end
    end
    info = {
      data_source_url: data_source_url,
      name: name,
      first_name: first_name,
      middle_name: middle_name,
      last_name: last_name,
      registration_status: registration_status,
      bar_number: bar_number,
      date_admitted: date_admitted,
      address_original: address_original,
      law_firm_name: law_firm_name,
      law_firm_address: law_firm_address,
      law_firm_city: law_firm_city,
      law_firm_state: law_firm_state,
      law_firm_zip: law_firm_zip,
      phone: phone,
      fax: fax,
      email: email,
      website: website,
      law_school: law_school
    }
    info
  end

  def name_split(name)
    last_name = name.split(',')[0].strip
    first_name = name.split(',')[1].strip.split(' ')[0].strip
    middle_name = name.split(',')[1].strip.split(' ')
    if middle_name.length > 1
      middle_name.shift(1)
      middle_name = middle_name.join(' ').squeeze(' ').strip
    else
      middle_name = nil
    end
    [first_name, middle_name, last_name]
  end

  def items_info(details)
    address_original = nil
    phone = nil
    fax = nil
    email = nil
    website = nil
    items = details.css('div > p')
    items.each do |item|
      if item.text.include?('Address:')
        address_original = item.text.gsub('Address:', '').strip
        address_original = nil if address_original.blank?
      end
      if item.text.include?('Phone:') or item.text.include?('Fax:')
        phone_fax = item.text.split('|')
        phone_fax.each do |pf|
          if pf.include?('Phone:')
            phone = pf.gsub('Phone:', '').gsub('Not Available', '').gsub(/\s/,' ').gsub(' ', ' ').squeeze(' ').strip
            phone = nil if phone.blank?
          end
          if pf.include?('Fax:')
            fax = pf.gsub('Fax:', '').gsub('Not Available', '').gsub(/\s/,' ').gsub(' ', ' ').squeeze(' ').strip
            fax = nil if fax.blank?
          end
        end
      end
      if item.text.include?('Email:') or item.text.include?('Website:')
        email_website = item.to_s.split('|')
        email_website.each do |ew|
          if ew.include?('Website:')
            website = ew.gsub('Website:', '').gsub('Not Available', '').gsub(/\s/,' ').gsub(' ', ' ')
            website = Nokogiri::HTML.parse(website).text.squeeze(' ').strip
            website = nil if website.blank?
          end
          if ew.include?('Email:')
            email = ew.gsub('Email:', '').gsub('Not Available', '').gsub('<span>.</span>','.').gsub(/\s/,' ').gsub(' ', ' ').squeeze(' ').strip
            email = nil if email.blank?
          end
        end
      end
    end
    [address_original, phone, fax, website, email]
  end

  def email_find(emails, name)
    emails = Nokogiri::HTML.parse(emails).css('span')
    name_items = name.split(' ').map{|item| item.gsub(/[,.]/,'').downcase}
    emails.each do |item|
      item = item.text
      name_items.each do |name_item|
        item_check = item.split('@')[0]
        if item_check.include?(name_item) && name_item.length > 1
          return item
        end
      end
    end
    nil
  end

  def law_firm(address_original)
    law_firm_name = nil
    law_firm_address = nil
    law_firm_city = nil
    law_firm_state = nil
    law_firm_zip = nil
    unless address_original.blank?
      address_ar = address_original.split(',')
      if address_ar[-1].match(/\d/)
        state_zip = address_ar[-1].strip.split(' ')
        address_ar.pop(1)
        address_ar.pop(1) if address_ar[-1].match(/\d/) || address_ar[-1].strip.length == 2
        law_firm_city = address_ar[-1].strip
        if state_zip.length > 1
          law_firm_state = state_zip[0].strip
          law_firm_zip = state_zip[1].strip
        else
          law_firm_state = nil
          law_firm_zip = state_zip[0].strip
        end
        address_ar.pop(1)
      else
        if address_ar[-1].strip.length == 2
          law_firm_state = address_ar[-1].strip
          address_ar.pop(1)
          law_firm_city = address_ar[-1].strip
          law_firm_zip = nil
          address_ar.pop(1)
        else
          law_firm_city = address_ar[-1].strip
          law_firm_state = nil
          law_firm_zip = nil
          address_ar.pop(1)
        end
      end
      address_ar = address_ar.join(',')
      address_ar = address_ar.gsub(' ','').squeeze(' ')
      address_ar = address_ar.gsub(/\s+,/,',').gsub('istrict,','istrict')
      address_ar = address_ar.gsub(/([Bb][Ll][Vv][Dd]\.?|[Bb]oulevard|[Bb]l),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Ss][Tt][Rr][Ee][Ee][Tt]|[Ss][Tt][Ee]?\.?),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Aa][Vv][Ee]?\.?|[Aa]venue),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Dd][Rr]\.?|[Dd][Rr][Ii][Vv][Ee]),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Rr][Dd]\.?|[Rr]oad),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Bb]ldg?\.?|[Bb]uilding),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Hh][Ww][Yy]\.?|[Hh]ighway),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Ff][Ll]\.?|[Ff]loor?),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Pp]kwy\.?|[Pp]arkway),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Tt]owers?),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Ss]tars?),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Cc]enter),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Pp]lz|[Pp]laza),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Cc]ir\.?(cle)?),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Pp][Ll]\.?(ace)?),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Rr]oute),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Ll]a?ne?),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Ss]uite?),/){|item| item.chop!}
      address_ar = address_ar.gsub(/([Nn]orth|[Ww]est|[Ss]outh|[Ee]ast),/){|item| item.chop!}
      address_ar = address_ar.gsub(/( [Cc]\.?[Tt]\.?| [Jj]\.?[Rr]\.?| [NnSs]\.?[Ww]\.?| [Rr]\.?[NnLl]\.?| [NnSs]\.?[Ee]\.?),/){|item| item.chop!}
      address_ar = address_ar.gsub(/( [Ww]ay| [Bb]roadway| [Rr]eal| [Aa]nd| [Ss]quare| [Ss]lough| [Ww]ing| [Mm]arket),/){|item| item.chop!}
      address_ar = address_ar.gsub(/( [Uu]nit| [Cc]ourt| [Pp]ark| [Ee]nterprise| [Pp]acifica| [Cc]arlsbad| [Cc]anyon),/){|item| item.chop!}
      address_ar = address_ar.gsub(/( [Aa]mericas| [Ss]anders| [Gg]rand| [Ii]sland|[ Vv]entura| [Ll]oop| [Pp]yramid),/){|item| item.chop!}
      address_ar = address_ar.gsub(/( [Tt]ordo| [Hh]all| [Hh]ouse| [Ss]onoma| [Cc]rossing| [Uu]pstairs| [Pp]residio| [Mm]all),/){|item| item.chop!}
      address_ar = address_ar.gsub(/( [Aa]ngeloalcid| [Ee]xpy| [Cc]ourthouse| [Cc][Tt][Rr]| [Pp][Mm][Bb]),/){|item| item.chop!}
      address_ar = address_ar.gsub(/( [Dd][Rr] [Ee]| [Ll][Nn] #[Cc]| [Pp]ark [Ee]ast| #| [Hh]all of [Aa]dmin| [Cc]ity [Aa]ttorney),/){|item| item.chop!}
      address_ar = address_ar.gsub(/( [Mm]itchell [Nn]| [Cc]hief [Cc]ounsel),/){|item| item.chop!}
      address_ar = address_ar.gsub(/(([Ss]uite?|[Aa]ve|[Aa]venue|[Bb]ox|[Uu]nit|[Pp]ark|[Bb]lvd) [a-zA-Z]),/){|item| item.chop!}
      address_ar = address_ar.gsub(/, (PO Box [^,]+),/){|item| item.chop!}
      address_ar = address_ar.gsub(/, ((Building|Bldg) [^,]+),/){|item| item.chop!}
      address_ar = address_ar.gsub(/, (\d+ [^,]+),/){|item| item.chop!}
      address_ar = address_ar.gsub(/(-\d+[a-zA-Z]+),/){|item| item.chop!}
      address_ar = address_ar.gsub(/(\d+ [^,]*([Dd][Rr][Ii][Vv][Ee]|[Ss][Qq]|[Aa][Vv][Ee]([Nn][Uu][Ee])?|[Hh][Ww][Yy]|[Ww][Aa][Yy]|[Ss][Tt]([Ee])?|[Ll][Nn]|[Ff][Ww][Yy]|[Pp][Kk]|[Ss][Tt]([Rr][Ee][Ee][Tt])?|[Rr][Oo][Uu][Tt][Ee]|[Pp][Ll][Cc]|[Bb][Ll][Dd][Gg])+ [^,]*),/){|item| item.chop!}
      address_ar = address_ar.gsub(/(\d+ [^,]*([Dd][Rr][Ii][Vv][Ee]|[Ss][Qq]|[Aa][Vv][Ee]([Nn][Uu][Ee])?|[Hh][Ww][Yy]|[Ww][Aa][Yy]|[Ss][Tt]([Ee])?|[Ll][Nn]|[Ff][Ww][Yy]|[Pp][Kk]|[Ss][Tt]([Rr][Ee][Ee][Tt])?|[Rr][Oo][Uu][Tt][Ee]|[Pp][Ll][Cc]|[Bb][Ll][Dd][Gg])+),/){|item| item.chop!}
      address_ar = address_ar.gsub(/(\d),/){|item| item.chop!}
      address_ar = address_ar.squeeze(' ').split(',').reject(&:blank?)
      if address_ar.blank?
      elsif address_ar.count == 1
        law_firm_address = address_ar[0].strip
      else
        law_firm_address = address_ar[-1].strip
        address_ar.pop(1)
        address_str = address_ar.join(',')
        law_firm_name = address_str
      end
    end
    [law_firm_name, law_firm_address, law_firm_city, law_firm_state, law_firm_zip]
  end

  def law_school(details)
    law_school = nil
    items = details.css('#panelMoreDetail-1 > p')
    items.each do |item|
      if item.text.include?('Law School:')
        law_school = item.text.gsub('Law School:', '').gsub('See Registration Card', '').gsub('Not Available', '')
        law_school = law_school.gsub('<span>.</span>','.').gsub(/\s/,' ').gsub(' ', ' ').squeeze(' ').strip
        law_school = nil if law_school.blank?
      end
    end
    law_school
  end
end