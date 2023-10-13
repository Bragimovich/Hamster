# frozen_string_literal: true

class Parser < Hamster::Parser

  def fetch_all_links(html)
    document = Nokogiri::HTML(html.force_encoding("utf-8"))
    document.css("table.dataTable tbody tr").map{|e| "https://apps.isb.idaho.gov/licensing/" + e.css("td")[0].css("a").attr("href").value}
  end
  
  def parser(html, link, states_array, run_id)
    document = Nokogiri::HTML(html.force_encoding("utf-8"))
    name     = document.css('.panel-title')[0].text.strip rescue nil
    data_tag = document.css('.panel-body')[0]
    law_firm_address    = get_value(data_tag, "Mailing Address")
    street_address      = (!law_firm_address.nil? and law_firm_address.split("\n").count > 1)? law_firm_address.split("\n")[..-2].join("\n") : nil
    law_firm_name       = get_value(data_tag, "Firm")
    law_firm_state      = law_firm_address.split("\n")[1].split(",")[1].tr('(0-9)', "").gsub("-", "").strip rescue nil
    law_firm_city       = law_firm_address.split("\n")[1].split(",")[0].strip rescue nil
    law_firm_zip        = law_firm_address.split("\n")[1].split(",")[1].tr('(A-Z)', "").tr('(a-z)', "").strip rescue nil
    phone               = get_value(data_tag, "Phone")
    email               = get_value(data_tag, "Bar Email Address")
    date                = get_value(data_tag, "Admittance Date")
    date_admitted       = DateTime.strptime(date, "%m/%d/%Y").to_date rescue nil
    registration_status = get_value(data_tag, "Status")
    website             = get_value(data_tag, "Website Address")
    fax                 = get_value(data_tag, "Fax")
    court_email         = get_value(data_tag, "Court eService Email")
    data_hash = {}
    data_hash[:name]             =  name
    data_hash[:link]             = link
    data_hash[:law_firm_name]    = law_firm_name
    data_hash[:law_firm_address] = law_firm_address
    data_hash[:law_firm_street]  = street_address
    data_hash[:phone]            = phone
    data_hash[:fax]              = fax
    data_hash[:email]            = email
    data_hash[:website]          = website
    data_hash[:court_email]      = court_email
    data_hash[:status]           = registration_status
    data_hash[:date_admitted]    = date_admitted
    data_hash                    = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash]         = create_md5_hash(data_hash)
    data_hash[:law_firm_zip]     = law_firm_zip
    data_hash[:law_firm_state]   = law_firm_state
    data_hash[:law_firm_city]    = law_firm_city
    data_hash                    = check_state(data_hash, states_array)
    data_hash[:run_id]           = run_id
    data_hash
  end

  private

  def check_state(data_hash, states_array)
    unless states_array.include? data_hash[:law_firm_state]
      data_hash[:law_firm_state] = nil
      data_hash[:law_firm_city]  = nil
      data_hash[:law_firm_zip]   = nil
    end
    data_hash
  end

  def get_value(data, title)
    values = data.css("dt").select{|e| e.text.downcase.include? "#{title}".downcase}
    if values.empty?
      value = nil
    else
      if title == 'Mailing Address'
        value = []
        while true
          data = values[0]
          address_line = get_element(data).text.squish rescue nil
          if address_line.nil?
            return value.split.join("\n")
          elsif address_line == ""
            return nil
          end
          value << address_line
          values[0] = values[0].next_element
        end
      else
        value = values[0].next_element.text.squish rescue nil
      end
    end
    value
  end

  def get_element(value)
    value.next_element rescue nil
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
