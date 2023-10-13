# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize(doc)
    @html = Nokogiri::HTML(doc.force_encoding("utf-8"))
  end

  def lawyers_list
    records = @html.css('body > div > main > div > table > tbody > tr')
    return [] if records.count == 0
    
    records.map do |el| 
      tag_a = el.css('td.text-center a') 
      link = tag_a.attr('href').text
      reg_num = link[/(?<=regNum=)\d+/]
      {link: link, reg_num: reg_num}
    end
  end

  def lawyer_data(run_id)
    name          = scrap_by('Attorney Name') 
    bar_number    = scrap_by('Registration Number') 
    link          = "https://directory-kard.kscourts.org/Home/Details?regNum=#{bar_number}"
    date          = scrap_by('Date Of Admission') { |el| el.split('/') }
    date_admited  = date ? correct_date(date) : nil
    status        = scrap_by('Current Status')  
    phone         = scrap_by('Business Phone')
    fax           = scrap_by('Business Fax')

    law_firm_name     = nil
    law_firm_address  = nil
    raw_adress        = nil
    law_firm_zip      = nil
    law_firm_city     = nil
    law_firm_state    = nil
    law_firm_county   = nil

    adress_elements = @html.css("div.row div.col-md-6").select { |s| s.text.include? 'Business Mailing Address' }[0].next_element.css('p') rescue nil

    unless adress_elements&.empty?
      law_firm_address = adress_elements.size > 2 ?  adress_elements[1..] : adress_elements
      law_firm_name = adress_elements.first.text.squish rescue nil if adress_elements.size > 2
      law_firm_address = law_firm_address.inject([]) { |arr, el| arr << el.text }.join("\n").strip
      shift = adress_elements.last.text.strip == 'United States' && adress_elements.size >= 2 ? -2 : -1
      location = adress_elements[shift].text.strip.squeeze(' ').match pattern_adress
      raw_adress = adress_elements.to_s
    end
    
    if location.present?
      law_firm_state = clean(location[:state]) if location[:state]
      law_firm_city  = clean(location[:city].split(',').pop.strip) if location[:city]
      law_firm_zip   = clean((location[:zip].match?(/\d{5}[^\d]+\d{4}/) ? location[:zip].split(/[^\d]/).join('-').squeeze('-') : location[:zip])) if location[:zip]
    end

    data_for_md5 = { 
      name:                 name,
      bar_number:           bar_number,
      registration_status:  status,
      date_admited:         date_admited,
      phone:                phone,
      fax:                  fax,
      law_firm_name:        law_firm_name&.empty? ? nil : law_firm_name,
      law_firm_address:     law_firm_address&.empty? ? nil : law_firm_address,
      law_firm_zip:         law_firm_zip&.empty? ? nil : law_firm_zip,
      law_firm_city:        law_firm_city&.empty? ? nil : law_firm_city,
      law_firm_state:       law_firm_state&.empty? ? nil : law_firm_state,
      data_source_url:      link   
    }                             

    data_hash = {
      bar_number:                 bar_number,
      name:                       name,
      date_admited:               date_admited,
      registration_status:        status,
      phone:                      phone,
      fax:                        fax,
      law_firm_name:              law_firm_name&.empty? ? nil : law_firm_name,
      law_firm_address:           law_firm_address&.empty? ? nil : law_firm_address,
      raw_address:                raw_adress&.empty? ? nil : raw_adress,
      law_firm_zip:               law_firm_zip&.empty? ? nil : law_firm_zip,
      law_firm_city:              law_firm_city&.empty? ? nil : law_firm_city,
      law_firm_state:             law_firm_state&.empty? ? nil : law_firm_state, 
      data_source_url:            link,
      md5_hash:                   create_md5_hash(data_for_md5),
      run_id:                     run_id,
      touched_run_id:             run_id
    }

    KSCourtKscourtsOrg.flail { |k| [k, data_hash[k]] }
  end 

  private

  def scrap_by(value, &block)
    result = @html.css("div.row div.col-md-6").select { |s| s.text.include? value }[0].next_element.text.squish
    result = block.call result if block_given?
    result.empty? ? nil : result
  rescue 
    nil
  end

  def correct_date(date)
    month = date.shift
    day = date.shift
    Date.parse("#{date[0]}-#{month}-#{day}").strftime("%Y-%m-%d")
  end

  def clean(text)
    text.gsub(%r{[^-.,:;?!@#$%^&*()+=®©™\\|/\]\[\}\{<>~`[:word:] ]+}, '').squeeze(' ').strip
  end  

  def pattern_adress
    zip_re         = '(?<zip>(?>\[?\d{5}\]?(?> ?[-–] ?\[?\d{4}\]?)?)|(?>[0-9a-z]{3}\s?[-–0-9a-z]{3,4}))' # it finds US, UK and Canadian zips
    location_re    = %r{(?<city>.+), (?<state>[-() a-z]+) #{zip_re}(?>, (?<country>[ a-z]+))?$}i
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    md5_hash = Digest::MD5.hexdigest data_string
  end
end
