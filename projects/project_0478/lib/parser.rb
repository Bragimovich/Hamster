# frozen_string_literal: true
class Parser < Hamster::Parser
  def initialize(doc)
    @html = Nokogiri::HTML doc
  end

  def lawyers_list
    @html.css('.directory_db_name').css('a').map { |link| link.attr("href") }
  end

  def lawyer_data
    link = @html.css('.inline-popup').
                  css('a').attr("onclick").value.
                  gsub("javascript:genericSocialShare('http://www.facebook.com/sharer.php?u=", "").
                  gsub("')", "")
    name = @html.css('.directory_db_name').text.delete("\r\n").strip
    header = @html.css('.directory_db_job_title')
    contact_info = @html.css('.phone')
    status = header.css('p').select{|s| s.text.include? 'Membership Status:'}[0].text.gsub('Membership Status:', '').strip rescue nil
    date = header.css('p').select{|s| s.text.include? 'Member Since:'}[0].text.gsub('Member Since:', '').strip.gsub("-", " ").split
    date_admited = Date.parse((date[2] + date[0] + date[1])).strftime("%Y-%m-%d")
    employer_name = header.css('p').select{|s| s.text.include? 'Employer Name: '}[0].text.gsub('Employer Name: ', '').strip rescue nil
    practice = @html.css('.check-mark-bullet').css('li').text rescue nil
    position_title = header.css('p').
                            select{|s| s.text.include? 'Position/Title at Employer: '}[0].
                            text.gsub('Position/Title at Employer: ', '').
                            strip rescue nil
    phone = contact_info.select{|s| s.text.include? 'Phone Number:'}[0].text.gsub('Phone Number:', '').strip rescue nil
    email = @html.css('.email').select{|s| s.text.include? 'Email Address:'}[0].text.gsub('Email Address:', '').strip rescue nil
    web_site = contact_info.select{|s| s.text.include? 'Website:'}[0].text.gsub('Website:', '').strip rescue nil
    fax_num = contact_info.select{|s| s.text.include? 'Fax Number:'}[0].text.gsub('Fax Number:', '').split rescue nil
    fax = fax_num[0] + fax_num[1] + fax_num[2]  rescue nil
    address = contact_info.select{|s| s.text.include? 'Mailing Address:'}[0].text.gsub('Mailing Address:', '').strip rescue nil
    city_separated = address.split(',')
    state_zip = city_separated[-1].split
    law_firm_zip = state_zip.last
    law_firm_country = state_zip[0...-1].join(' ')
    law_firm_city = city_separated[-3] if !city_separated[-3].empty?
    law_firm_state = city_separated[-2].strip
    law_school = @html.css('.directory_db_contact_info').
                      select{|s| s.text.include? 'Name of Law School:'}[0].
                      text.gsub('Name of Law School:', '').
                      strip rescue nil
    jurisdictions = @html.css('.directory_db_contact_info').
                          select{|s| s.text.include? 'Jurisdictions other than Guam: '}[0].
                          text.gsub('Jurisdictions other than Guam: ', '').
                          gsub(/\s+/, " ").
                          strip rescue nil

    dig_data = { 
      name: name,
      registration_status: status,
      date_admited: date_admited,
      law_firm_name: employer_name,
      sections: practice,
      type: position_title,
      email: email,
      website: web_site,
      phone: phone,
      fax: fax,
      law_firm_address: address,
      law_school: law_school,
      other_jurisdictions: jurisdictions,
      data_source_url: link 
    }

    {
      name: name,
      registration_status: status,
      date_admited: date_admited, 
      law_firm_name: employer_name,
      sections: practice,
      type: position_title,
      phone: phone,
      email: email,
      website: web_site,
      fax: fax,
      law_firm_address: address,
      law_firm_city: law_firm_city,
      law_firm_country: law_firm_country,
      law_firm_zip: law_firm_zip,
      law_firm_state: law_firm_state,
      law_school: law_school,
      other_jurisdictions: jurisdictions,
      data_source_url: link,
      digest: create_md5_hash(dig_data)
    }
  end
  
  def create_md5_hash(dig_data)
    str = ""
    dig_data.each { |field| str += field.to_s}
    digest = Digest::MD5.new.hexdigest(str)
  end
end
