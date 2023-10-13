# frozen_string_literal: true
class Parser < Hamster::Parser

  def fetch_state(response)
    parse_page(response).css("#UserState9new option")[1..-1].map{|e| e.text.downcase.split.join("-")}
  end

  def parse_page(response)
    Nokogiri::HTML(response.force_encoding("utf-8"))
  end

  def lawyer_body(response)
    parse_page(response).css("section.r-attorney ul.clearfix li")
  end

  def get_lawyer_url(response)
    response.css("section.profileDes h3 a").attr("href").value rescue nil
  end

  def get_lawyer_data(record)
    names         = []
    sections      = []
    date_admitted = []
    record.each do |response|
      names         << response.css("section.profileDes h3").first.text.squish
      sections      << response.css("section.profileDes .skillTag").first.text.squish
      date_admitted << response.css("section.profileDes p.oldRecord").first.text.squish.split("|").last.split(":").last.strip
    end
    [names, sections, date_admitted]
  end

  def get_data(response, name, date_admit, section, link, run_id)
    data_hash    = {}
    document     = parse_page(response)
    contact_info = document.css(".hlfWidtleft").select{|e| e.text.include? "Contact Information"}
    data_hash[:phone], data_hash[:email] = contact_info_parser(contact_info)
    data_hash[:typical_hourly_rate], data_hash[:typical_fixed_fee], data_hash[:typical_contingency_fee] = get_pricing(document)
    data_hash[:name]             = name
    data_hash[:date_admitted]    = Date.strptime(date_admit, "%m/%d/%Y").to_date rescue nil
    data_hash[:attorney_type]    = document.css("div.jobAppDetailTP h4").text
    website                      = document.css(".hlfWidtright").select{|e| e.text.include? "Website"}.first.css("p").first.text.strip
    data_hash[:website]          = website == "No Information added" ? nil : website
    data_hash[:law_firm_name]    = document.css(".applicantDtl p").first.text.squish rescue nil
    data_hash[:law_firm_address] = document.css("section.jobShortDetail .diffDetail").last.text.strip
    county, city, state          = get_address_values (data_hash[:law_firm_address].split(","))
    data_hash[:law_firm_address] = data_hash[:law_firm_address].split(",").map{|e| e.squish}.reject{|s| s.squish.empty?}.join(", ")
    data_hash[:jurisdiction]     = document.css('h4').select{|e| e.text == 'Jurisdictions'}.first.next_element.text.squish
    data_hash[:sections]         = section
    data_hash[:md5_hash]         = create_md5_hash(data_hash)
    data_hash[:data_source_url]  = link
    data_hash[:law_firm_county]  = county
    data_hash[:law_firm_city]    = city
    data_hash[:law_firm_state]   = state
    data_hash[:run_id]           = run_id
    data_hash[:touched_run_id]   = run_id
    data_hash.select { |_, value| value!="" }
  end

  private

  def get_address_values(address)
   county = nil_check(address.last.strip.gsub("County", ""))
   city   = nil_check(address.first.strip)
   state  = nil_check(address[1].strip)
   [county, city, state]
  end

  def nil_check(val)
    val = val == "" ? nil : val
  end

  def contact_info_parser(contact_info)
    phone, email = nil
    if contact_info != []
      unless (contact_info.first.text.include? "No Contact Information")
        phone = contact_info[0].children[2..].text.squish.split(",")[0] rescue nil
        email = contact_info[0].children[2..].text.squish.split(",")[1].squish rescue nil
        phone = nil if phone == "No Information added"
      end
    end
    [phone, email]
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def get_pricing(document)
    all_rates = document.css('div[class="diffDetail"]')[-2].css('text()').map(&:text).map(&:squish)
    rates = []
    all_rates.each do |e|
      if e.split(':')[-1].gsub('$', '').squish == '--'
        rates << nil
      else
        rates << e.split(':')[-1].gsub('$', '').squish
      end
    end
    rates
  end
end
